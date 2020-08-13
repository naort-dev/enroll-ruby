# frozen_string_literal: true

module Operations
  module Individual
    # This class is invoked when we want to generate a passive renewal for an active enrollment.
    # It will validate the incoming enrollment if it can be renewed and call a different class
    # to generate the renewal enrollment.
    # For assisted renewals, it will fetch eligibility values from the DB for renewing enrollment.
    class RenewEnrollment
      include Dry::Monads[:result, :do]

      # @param [ HbxEnrollment ] hbx_enrollment Enrollment that needs to be renewed.
      # @param [ Date ] effective_on Effective Date of the renewal enrollment.
      # @return [ HbxEnrollment ] renewal_enrollment.
      def call(hbx_enrollment:, effective_on:)
        validated_enrollment = yield validate(hbx_enrollment, effective_on)
        eligibility_values   = yield fetch_eligibility_values(validated_enrollment, effective_on)
        renewal_enrollment   = yield renew_enrollment(validated_enrollment, effective_on, eligibility_values)

        Success(renewal_enrollment)
      end

      private

      def validate(enrollment, effective_on)
        return Failure('Given object is not a valid enrollment object') unless enrollment.is_a?(HbxEnrollment)
        return Failure('Given enrollment is not IVL by kind') unless enrollment.is_ivl_by_kind?
        return Failure('There exists active enrollments for given family in the year with renewal_benefit_coverage_period') unless enrollment.can_renew_coverage?(effective_on)

        Success(enrollment)
      end

      def fetch_eligibility_values(enrollment, effective_on)
        family = enrollment.family
        tax_household = family.active_household.latest_active_thh_with_year(effective_on.year)
        if tax_household
          max_aptc = tax_household.current_max_aptc.to_f
          default_percentage = EnrollRegistry[:aca_individual_assistance_benefits].setting(:default_applied_aptc_percentage).item
          applied_percentage = enrollment.elected_aptc_pct > 0 ? enrollment.elected_aptc_pct : default_percentage
          applied_aptc = max_aptc * applied_percentage
          data = { applied_percentage: applied_percentage,
                   applied_aptc: applied_aptc,
                   max_aptc: max_aptc,
                   csr_amt: tax_household.current_csr_percent_as_integer }
        end

        Success(data || {})
      end

      def renew_enrollment(enrollment, effective_on, eligibility_values)
        enrollment_renewal = Enrollments::IndividualMarket::FamilyEnrollmentRenewal.new
        enrollment_renewal.enrollment = enrollment
        enrollment_renewal.assisted = eligibility_values.present? ? true : false
        enrollment_renewal.aptc_values = eligibility_values
        enrollment_renewal.renewal_coverage_start = effective_on
        renewed_enrollment = enrollment_renewal.renew
        if renewed_enrollment.is_a?(HbxEnrollment)
          Success(renewed_enrollment)
        else
          Failure('Unable to renew the enrollment')
        end
      end
    end
  end
end
