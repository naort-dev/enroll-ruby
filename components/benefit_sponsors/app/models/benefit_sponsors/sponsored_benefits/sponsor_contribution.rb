module BenefitSponsors
  class SponsoredBenefits::SponsorContribution
    include Mongoid::Document

    embeds_many :contribution_levels,
                class_name: "BenefitSponsors::SponsoredBenefits::ContributionLevel"

    validate :validate_contribution_levels

    def validate_contribution_levels
      raise NotImplementedError.new("subclass responsibility")
    end
  end
end
