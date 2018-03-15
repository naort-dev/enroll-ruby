module SponsoredBenefits
  module BenefitMarkets
    # AcaShopInitialApplicationConfiguration settings
    class AcaShopInitialApplicationConfiguration
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :benefit_market, class_name: "SponsoredBenefits::BenefitMarkets::AcaShopConfiguration"

      field :pub_due_dom, as: :publish_due_day_of_month, type: Integer, default: 5
      field :erlst_strt_prior_eff_months, as: :earliest_strt_prior_to_effective_on_months, type: Integer, default: -3
      field :appeal_per_aft_app_denial_dys, as: :appeal_period_after_app_denial_days, type: Integer, default: 30
      field :quiet_per_end, as: :quiet_period_end_on, type: Integer, default: 28
      # After submitting an ineligible plan year application, time period an Employer must wait
      field :inelig_per_aft_app_denial_dys, as: :ineligible_period_after_application_denial_days, type: Integer, default: 90
    end
  end
end
