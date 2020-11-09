# frozen_string_literal: true

require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe BenefitSponsors::Operations::BenefitApplications::Reinstate, dbclean: :after_each do
  let!(:effective_period_start_on) { TimeKeeper.date_of_record.beginning_of_year }
  let!(:effective_period_end_on)   { TimeKeeper.date_of_record.end_of_year }
  let!(:site) { BenefitSponsors::SiteSpecHelpers.create_site_with_hbx_profile_and_empty_benefit_market }
  let!(:benefit_market) { site.benefit_markets.first }
  let!(:effective_period) { (effective_period_start_on..effective_period_end_on) }
  let!(:current_benefit_market_catalog) do
    BenefitSponsors::ProductSpecHelpers.construct_benefit_market_catalog_with_renewal_catalog(site, benefit_market, effective_period)
    benefit_market.benefit_market_catalogs.where(
      "application_period.min" => effective_period_start_on
    ).first
  end

  let!(:service_areas) do
    ::BenefitMarkets::Locations::ServiceArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).all.to_a
  end

  let!(:rating_area) do
    ::BenefitMarkets::Locations::RatingArea.where(
      :active_year => current_benefit_market_catalog.application_period.min.year
    ).first
  end
  include_context 'setup initial benefit application'

  context 'success' do
    let(:current_effective_date) {TimeKeeper.date_of_record.beginning_of_year}

    before do
      initial_application.benefit_packages.each do |bp|
        bp.sponsored_benefits.each {|spon_benefit| create_pd(spon_benefit)}
      end
      initial_application.terminate_enrollment!
      initial_application.update_attributes!(termination_reason: 'Testing', terminated_on: TimeKeeper.date_of_record.end_of_month)
      @result = subject.call({benefit_application: initial_application})
    end

    it 'should return a success with a BenefitApplication' do
      expect(@result.success).to be_a(BenefitSponsors::BenefitApplications::BenefitApplication)
    end

    it 'should return a BenefitApplication with aasm_state being reinstated' do
      expect(@result.success.aasm_state).to eq(:reinstated)
    end
  end
end

def create_pd(spon_benefit)
  pricing_determination = BenefitSponsors::SponsoredBenefits::PricingDetermination.new({group_size: 4, participation_rate: 75})
  spon_benefit.pricing_determinations << pricing_determination
  pricing_unit_id = spon_benefit.product_package.pricing_model.pricing_units.first.id
  pricing_determination_tier = BenefitSponsors::SponsoredBenefits::PricingDeterminationTier.new({pricing_unit_id: pricing_unit_id, price: 320.00})
  pricing_determination.pricing_determination_tiers << pricing_determination_tier
  spon_benefit.save!
end
