# frozen_string_literal: true

module Services
  class IvlEnrollmentRenewalService

    def initialize(enrollment)
      raise "Hbx Enrollment Missing!!!" if enrollment.nil?

      @hbx_enrollment = enrollment
    end

    def assign(aptc_values)
      raise 'Provide aptc values {applied_aptc:, max_aptc:}' if aptc_values_missing?(aptc_values)

      if EnrollRegistry.feature_enabled?(:temporary_configuration_enable_multi_tax_household_feature)
        @hbx_enrollment.applied_aptc_amount = aptc_values[:applied_aptc]
        @hbx_enrollment.elected_aptc_pct = aptc_values[:applied_percentage]
        @hbx_enrollment.aggregate_aptc_amount = aptc_values[:max_aptc]
        @hbx_enrollment.ehb_premium = aptc_values[:ehb_premium]
      else
        applied_aptc_amt = calculate_applicable_aptc(aptc_values)
        @hbx_enrollment.applied_aptc_amount = applied_aptc_amt.round(2)
        @hbx_enrollment.elected_aptc_pct = applied_aptc_amt / aptc_values[:max_aptc].to_f
      end

      @hbx_enrollment
    end

    private

    def aptc_values_missing?(aptc_values)
      aptc_keys = [:applied_aptc, :max_aptc]
      return true if aptc_keys.any?{ |aptc_key| aptc_values.keys.exclude?(aptc_key) } || aptc_keys.any?{ |aptc_key| aptc_values[aptc_key].blank? }

      false
    end

    def applicable_aptc(selected_aptc)
      product_id = @hbx_enrollment.product.id.to_s
      applicable_aptc_service = ::Services::ApplicableAptcService.new(@hbx_enrollment.id, @hbx_enrollment.effective_on, selected_aptc, [product_id])
      applicable_aptc_service.applicable_aptcs[product_id]
    end

    def calculate_applicable_aptc(aptc_values)
      applicable_aptc(aptc_values[:applied_aptc].to_f)
    end
  end
end
