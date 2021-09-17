# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation creates a new renewal_draft application from a given family identifier(BSON ID),
      class CreateApplicationRenewal
        include Dry::Monads[:result, :do, :try]
        include EventSource::Command

        # @param [Hash] opts The options to generate renewal_draft application
        # @option opts [BSON::ObjectId] :family_id (required)
        # @option opts [Integer] :renewal_year (required)
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params       = yield validate_input_params(params)
          latest_application     = yield find_latest_application(validated_params)
          renewal_draft_app      = yield renew_application(latest_application, validated_params)
          event                  = yield build_event(renewal_draft_app)
          publish(event)

          Success(renewal_draft_app)
        end

        private

        def validate_input_params(params)
          return Failure('Missing family_id key') unless params.key?(:family_id)
          return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
          return Failure("Invalid value: #{params[:family_id]} for key family_id, must be a valid object identifier") if params[:family_id].nil?
          return Failure("Cannot find family with input value: #{params[:family_id]} for key family_id") if ::Family.where(id: params[:family_id]).first.nil?
          return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)
          Success(params)
        end

        def find_latest_application(validated_params)
          applications_by_family = ::FinancialAssistance::Application.where(family_id: validated_params[:family_id])

          if applications_by_family.by_year(validated_params[:renewal_year]).present?
            Rails.logger.error "Renewal application already created for #{validated_params}"
            return Failure("Renewal application already created for #{validated_params}")
          end

          application = applications_by_family
            .by_year(validated_params[:renewal_year].pred)
            .renewal_eligible.created_asc.last

          if application.present?
            Success(application)
          else
            Rails.logger.error "Could not find any applications that are renewal eligible: #{validated_params}."
            Failure("Could not find any applications that are renewal eligible: #{validated_params}.")
          end
        end

        def renew_application(application, validated_params)
          application = create_renewal_draft_application(application, validated_params)

          if application.failure?
            Rails.logger.error "Unable to create renewal application #{application.failure.errors} with #{validated_params}"
            return Failure("Unable to create renewal application #{application.failure.errors} with #{validated_params}")
          end
          
          application
        end

        def create_renewal_draft_application(application, validated_params)
          Try() do
            service = ::FinancialAssistance::Services::ApplicationService.new(application_id: application.id)
            service.copy!
          end.bind do |renewal_application|
            years_to_renew = calculate_years_to_renew(application)

            renewal_application.assign_attributes(
              aasm_state: 'renewal_draft',
              assistance_year: validated_params[:renewal_year],
              years_to_renew: years_to_renew,
              renewal_base_year: application.renewal_base_year,
              predecessor_id: application.id
            )

            renewal_application.save!
            Success(renewal_application)
          end.to_result
        end

        # Deduct one year from years_to_renew as this is a renewal application(application for prospective year)
        def calculate_years_to_renew(application)
          return 0 if application.years_to_renew.nil? || !application.years_to_renew.positive?
          application.years_to_renew.pred
        end

        def build_event(application)
          event("events.iap.applications.determinations.application_renewal_created", attributes: application.serializable_hash)
        end

        def publish(event)
          event.publish

          Success("Successfully published the payload for event: 'application_renewal_created'")
        end
      end
    end
  end
end
