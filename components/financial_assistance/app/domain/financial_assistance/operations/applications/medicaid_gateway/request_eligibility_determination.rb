# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'
require 'aca_entities/magi_medicaid/libraries/iap_library'

module FinancialAssistance
  module Operations
    module Applications
      module MedicaidGateway
        #medicaid Gateway
        class RequestEligibilityDetermination
          # Requests eligibility determination from medicaid gateway

          send(:include, Dry::Monads[:result, :do])
          include Acapi::Notifiers
          require 'securerandom'

          # @param [ Hash ] params Applicant Attributes
          # @return [ BenefitMarkets::Entities::Applicant ] applicant Applicant
          def call(application_id:)
            application    = yield find_application(application_id)
            application    = yield validate(application)
            payload_param  = yield construct_payload(application)
            payload_value  = yield validate_payload(payload_param)
            payload        = yield publish(payload_value, application)

            Success(payload)
          end

          private

          def find_application(application_id)
            application = FinancialAssistance::Application.find(application_id)

            Success(application)
          rescue Mongoid::Errors::DocumentNotFound
            Failure("Unable to find Application with ID #{application_id}.")
          end

          def validate(application)
            return Success(application) if application.submitted?
            Failure("Application is in #{application.aasm_state} state. Please submit application.")
          end

          def construct_payload(application)
            FinancialAssistance::Operations::Applications::Transformers::ApplicationTo::Cv3Application.new.call(application)
          end

          def validate_payload(payload)
            AcaEntities::MagiMedicaid::Operations::InitializeApplication.new.call(payload).failure.errors.to_h
            # Validate payload through aca_Entities
          end

          def request_eligibility_determination(payload, application)
            # notify("acapi.info.events.assistance_application.submitted", {
            #                                                                :correlation_id => SecureRandom.uuid.gsub("-",""),
            #                                                                :body => payload,
            #                                                                :family_id => application.family_id.to_s,
            #                                                                :assistance_application_id => application.hbx_id.to_s
            #                                                            })
            # Success(payload)
          end
        end
      end
    end
  end
end
