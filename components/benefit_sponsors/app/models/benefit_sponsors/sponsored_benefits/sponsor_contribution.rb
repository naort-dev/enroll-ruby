module BenefitSponsors
  class SponsoredBenefits::SponsorContribution
    include Mongoid::Document

    embedded_in :sponsored_benefit,
      class_name: "BenefitSponsors::SponsoredBenefits::SponsoredBenefit"
    embeds_many :contribution_levels,
                class_name: "BenefitSponsors::SponsoredBenefits::ContributionLevel"

    validate :validate_contribution_levels

    def validate_contribution_levels
      raise NotImplementedError.new("subclass responsibility")
    end

    def sic_code
      # Needs to return the most recent SIC CODE value recorded for this sponsorship
    end
  end
end
