module SponsoredBenefits
  module Organizations
    class AcaShopDcEmployerProfile < Profile


      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end
    end
  end
end
