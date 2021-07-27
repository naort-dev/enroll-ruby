# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module FinancialAssistance
  module Operations
    module Applications
      # This Operation creates a new renewal_draft application from a given family identifier(BSON ID),
      class CreateRenewalDraft
        include Dry::Monads[:result, :do]

        # @param [Hash] opts The options to generate renewal_draft application
        # @option opts [BSON::ObjectId] :family_id (required)
        # @option opts [Integer] :renewal_year (required)
        # @return [Dry::Monads::Result]
        def call(params)
          validated_params       = yield validate_input_params(params)
          latest_application     = yield find_latest_application(validated_params)
          determined_application = yield check_application_state(latest_application)
          renewal_draft_app      = yield create_renewal_draft_application(determined_application, validated_params)

          Success(renewal_draft_app)
        end

        private

        def validate_input_params(params)
          return Failure('Missing family_id key') unless params.key?(:family_id)
          return Failure('Missing renewal_year key') unless params.key?(:renewal_year)
          return Failure("Invalid value: #{params[:family_id]} for key family_id, must be a BSON object") if params[:family_id].nil? || !params[:family_id].is_a?(BSON::ObjectId)
          return Failure("Invalid value: #{params[:renewal_year]} for key renewal_year, must be an Integer") if params[:renewal_year].nil? || !params[:renewal_year].is_a?(Integer)
          Success(params)
        end

        def find_latest_application(validated_params)
          application = ::FinancialAssistance::Application.where(family_id: validated_params[:family_id], assistance_year: validated_params[:renewal_year].pred).created_asc.last
          application.present? ? Success(application) : Failure("Could not find any applications with the given inputs params: #{validated_params}.")
        end

        # Currently, we only allow applications which are in submitted or determined.
        def check_application_state(latest_application)
          eligible_states = ::FinancialAssistance::Application::RENEWAL_ELIGIBLE_STATES
          return Failure("Cannot generate renewal_draft for given application with aasm_state #{latest_application.aasm_state}. Application must be in one of #{eligible_states} states.") if eligible_states.exclude?(latest_application.aasm_state)
          Success(latest_application)
        end

        def create_renewal_draft_application(application, validated_params)
          service = ::FinancialAssistance::Services::ApplicationService.new(application_id: application.id)
          draft_app = service.copy!
          attach_additional_data(draft_app, application, validated_params)
          Success(draft_app)
        rescue StandardError => e
          Rails.logger.error "---CreateRenewalDraft: Unable to generate Renewal Draft Application for application with hbx_id: #{application.hbx_id}, error: #{e.backtrace}"
          Failure("Could not generate renewal draft for given application with hbx_id: #{application.hbx_id}, error: #{e.message}")
        end

        def attach_additional_data(draft_app, application, validated_params)
          # Using assign attributes instead of calling aasm event becuase 'renewal_draft' is the first state for a renewal application.
          draft_app.assign_attributes({ aasm_state: 'renewal_draft', assistance_year: validated_params[:renewal_year] })
          draft_app.predecessor = application
          draft_app.save!
        end
      end
    end
  end
end
