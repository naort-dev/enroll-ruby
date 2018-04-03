module BenefitSponsors
  module SponsoredBenefits
    class ReferenceProductFixedPercentSponsorContribution < FixedPercentSponsorContribution
      
      # Return the reference product for calculation.
      # @return [::BenefitMarket::Products::Product] the reference product
      def reference_product
        @reference_product
      end

      attr_writer :reference_product
    end
  end
end
