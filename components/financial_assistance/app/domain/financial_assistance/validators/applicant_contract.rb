# frozen_string_literal: true

module FinancialAssistance
  module Validators
    class ApplicantContract < Dry::Validation::Contract

      params do
        optional(:name_pfx).maybe(:string)
        required(:first_name).maybe(:string)
        optional(:middle_name).maybe(:string)
        required(:last_name).maybe(:string)
        optional(:name_sfx).maybe(:string)
        required(:ssn).maybe(:string)
        required(:gender).maybe(:string)
        required(:dob).filled(:date)

        optional(:is_primary_applicant).maybe(:bool)
        optional(:person_hbx_id).maybe(:string)
        optional(:ext_app_id).maybe(:string)
        optional(:family_member_id).maybe(Types::Bson)

        optional(:is_incarcerated).maybe(:bool)
        optional(:is_disabled).filled(:bool)
        optional(:ethnicity).maybe(:array)
        optional(:race).maybe(:string)
        optional(:indian_tribe_member).maybe(:bool)
        optional(:tribal_id).maybe(:string)
        optional(:tribal_state).maybe(:string)
        optional(:tribal_name).maybe(:string)
        optional(:tribe_codes).maybe(:array)
        optional(:health_service_eligible).maybe(:bool)
        optional(:health_service_through_referral).maybe(:bool)

        optional(:language_code).maybe(:string) # Fix Me
        optional(:no_dc_address).filled(:bool) # Fix Me
        optional(:is_homeless).maybe(:bool)
        optional(:is_temporarily_out_of_state).maybe(:bool)
        optional(:is_living_in_state).maybe(:bool)

        optional(:vlp_subject).maybe(:string)
        optional(:vlp_description).maybe(:string)
        optional(:alien_number).maybe(:string)
        optional(:i94_number).maybe(:string)
        optional(:visa_number).maybe(:string)
        optional(:passport_number).maybe(:string)
        optional(:sevis_id).maybe(:string)
        optional(:naturalization_number).maybe(:string)
        optional(:receipt_number).maybe(:string)
        optional(:citizenship_number).maybe(:string)
        optional(:card_number).maybe(:string)
        optional(:country_of_citizenship).maybe(:string)
        optional(:expiration_date).maybe(:date)
        optional(:issuing_country).maybe(:string)
        optional(:relationship).maybe(:string)

        optional(:no_ssn).maybe(:string)
        required(:citizen_status).maybe(:string)
        required(:is_consumer_role).filled(:bool)
        optional(:same_with_primary).maybe(:bool)
        required(:is_applying_coverage).filled(:bool)

        optional(:five_year_bar_applies).maybe(:bool)
        optional(:five_year_bar_met).maybe(:bool)
        optional(:qualified_non_citizen).maybe(:bool)

        optional(:addresses).maybe(:array)
        optional(:phones).maybe(:array)
        optional(:emails).maybe(:array)
        optional(:immigration_doc_statuses).maybe(:array)
        optional(:transfer_referral_reason).maybe(:string)
      end

      rule(:addresses).each do
        if key? && value
          if value.is_a?(Hash)
            result = ::FinancialAssistance::Validators::AddressContract.new.call(value)
            key.failure(text: "invalid address", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid addresses. Expected a hash.")
          end
        end
      end

      rule(:ssn, :no_ssn) do
        base.failure("SSN is missing") if values[:ssn].blank? && values[:no_ssn] == '0' && values[:is_applying_coverage]
      end

      rule(:is_primary_applicant) do
        if key? && value
          if value
            key.failure(text: "family_member_id should be present") if values[:family_member_id].blank?
            key.failure(text: "person hbx id should be present") if values[:person_hbx_id].blank?
          end
        end
      end

      rule(:is_incarcerated) do
        if values[:is_applying_coverage]
          key.failure(text: "Incarceration question must be answered") if values[:is_incarcerated].to_s.blank?
        end
      end

      rule(:indian_tribe_member) do
        if values[:is_applying_coverage]
          key.failure(text: "Indian tribe member question must be answered") if values[:indian_tribe_member].to_s.blank?
        end
      end

      rule(:phones).each do
        if key? && value
          if value.is_a?(Hash)
            result = ::FinancialAssistance::Validators::PhoneContract.new.call(value)
            key.failure(text: "invalid phone", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid phones. Expected a hash.")
          end
        end
      end

      rule(:emails).each do
        if key? && value
          if value.is_a?(Hash)
            result = ::FinancialAssistance::Validators::EmailContract.new.call(value)
            key.failure(text: "invalid email", error: result.errors.to_h) if result&.failure?
          else
            key.failure(text: "invalid emails. Expected a hash.")
          end
        end
      end
    end
  end
end
