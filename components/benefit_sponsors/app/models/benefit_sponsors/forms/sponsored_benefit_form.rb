module BenefitSponsors
  module Forms
    class SponsoredBenefitForm
      
      include Virtus.model
      include ActiveModel::Model

      attribute :id, String
      attribute :kind, String
      attribute :product_option_choice, String
      attribute :product_package_kind, String

      attribute :products, Array[BenefitProductForm]
      attribute :reference_plan_id, String

      attribute :sponsor_contribution, SponsorContributionForm
      attribute :pricing_determinations, Array[PricingDeterminationForm]

      attr_accessor :sponsor_contribution

      def sponsor_contribution_attributes=(attributes)
        @sponsor_contribution = SponsorContributionForm.new(attributes)
      end

      def self.for_new
        kinds.collect do |kind|
          form = self.new(kind: kind)
          form.sponsor_contribution = SponsorContributionForm.for_new
          form
        end
      end

      def self.kinds
        %w(health)
        # get kinds from catalog based on products/product packages
      end
    end
  end
end
