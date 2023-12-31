# frozen_string_literal: true

module FinancialAssistance
  module Entities
    # FinancialAssistance Applicant Entities for DC and ME
    class Applicant < Dry::Struct
      transform_keys(&:to_sym)

      attribute :name_pfx, Types::String.optional.meta(omittable: true)
      attribute :first_name, Types::String.optional
      attribute :middle_name, Types::String.optional.meta(omittable: true)
      attribute :last_name, Types::String.optional
      attribute :name_sfx, Types::String.optional.meta(omittable: true)
      attribute :ssn, Types::String.optional
      attribute :gender, Types::String.optional
      attribute :dob, Types::Date.optional
      attribute :is_primary_applicant, Types::Strict::Bool.meta(omittable: true)
      attribute :family_member_id, Types::Bson.optional.meta(omittable: true)
      attribute :person_hbx_id, Types::String.optional.meta(omittable: true)
      attribute :ext_app_id, Types::String.optional.meta(omittable: true)
      attribute :is_incarcerated, Types::Strict::Bool.optional.meta(omittable: true)
      attribute :is_disabled, Types::Strict::Bool.meta(omittable: true)
      attribute :ethnicity, Types::Array.optional.meta(omittable: true)
      attribute :race, Types::String.optional.meta(omittable: true)
      attribute :indian_tribe_member, Types::Bool.optional.meta(omittable: true)
      attribute :tribal_id, Types::String.optional.meta(omittable: true)
      attribute :tribal_state, Types::String.optional.meta(omittable: true)
      attribute :tribal_name, Types::String.optional.meta(omittable: true)
      attribute :tribe_codes, Types::Array.optional.meta(omittable: true)
      attribute :health_service_eligible, Types::Bool.optional.meta(omittable: true)
      attribute :health_service_through_referral, Types::Bool.optional.meta(omittable: true)

      attribute :language_code, Types::String.optional.meta(omittable: true)
      attribute :no_dc_address, Types::Strict::Bool.meta(omittable: true)
      attribute :is_homeless, Types::Strict::Bool.meta(omittable: true)
      attribute :is_living_in_state, Types::Strict::Bool.meta(omittable: true)

      attribute :no_ssn, Types::String.optional.meta(omittable: true)
      attribute :citizen_status, Types::String.optional
      attribute :is_consumer_role, Types::Strict::Bool
      attribute :is_resident_role, Types::Strict::Bool.meta(omittable: true)
      attribute :vlp_document_id, Types::String.optional.meta(omittable: true)
      attribute :same_with_primary, Types::Bool.optional.meta(omittable: true)
      attribute :is_applying_coverage, Types::Strict::Bool

      attribute :vlp_subject, Types::String.optional.meta(omittable: true)
      attribute :vlp_description, Types::String.optional.meta(omittable: true)
      attribute :alien_number, Types::String.optional.meta(omittable: true)
      attribute :i94_number, Types::String.optional.meta(omittable: true)
      attribute :visa_number, Types::String.optional.meta(omittable: true)
      attribute :passport_number, Types::String.optional.meta(omittable: true)
      attribute :sevis_id, Types::String.optional.meta(omittable: true)
      attribute :naturalization_number, Types::String.optional.meta(omittable: true)
      attribute :receipt_number, Types::String.optional.meta(omittable: true)
      attribute :citizenship_number, Types::String.optional.meta(omittable: true)
      attribute :card_number, Types::String.optional.meta(omittable: true)
      attribute :country_of_citizenship, Types::String.optional.meta(omittable: true)
      attribute :expiration_date, Types::Date.optional.meta(omittable: true)
      attribute :issuing_country, Types::String.optional.meta(omittable: true)
      attribute :relationship, Types::String.optional.meta(omittable: true)
      attribute :immigration_doc_statuses, Types::Array.of(Types::String).meta(omittable: true)

      attribute :addresses, Types::Array.of(FinancialAssistance::Entities::Address)
      attribute :emails, Types::Array.of(FinancialAssistance::Entities::Email)
      attribute :phones, Types::Array.of(FinancialAssistance::Entities::Phone)
      attribute :incomes, Types::Array.of(FinancialAssistance::Entities::Income).meta(omittable: true)

      attribute :is_temporarily_out_of_state, Types::Strict::Bool.meta(omittable: true) if EnrollRegistry[:enroll_app].settings(:site_key).item == :dc
      attribute :transfer_referral_reason, Types::String.optional.meta(omittable: true)
    end
  end
end
