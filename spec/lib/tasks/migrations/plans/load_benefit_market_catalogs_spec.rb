require 'rails_helper'

describe "load_benefit_market_catalogs" do
  before do
    DatabaseCleaner.clean

    Rake.application.rake_require 'tasks/migrations/plans/load_benefit_market_catalogs'
    Rake::Task.define_task(:environment)

    glob_pattern = File.join(Rails.root, "db/seedfiles/cca/issuer_profiles_seed.rb")
    load glob_pattern
    load_cca_issuer_profiles_seed

    start_date = TimeKeeper.date_of_record.all_quarter.min + 1.year
    end_date = TimeKeeper.date_of_record.all_quarter.max + 1.year
    application_period = Time.utc(start_date.year, start_date.month, start_date.day)..Time.utc(end_date.year, end_date.month, end_date.day)

    issuer_profiles = BenefitSponsors::Organizations::Organization.issuer_profiles.all
    FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[0].issuer_profile.id,
                       application_period: application_period, benefit_market_kind: :aca_shop,
                       kind: :health, product_package_kinds: [:single_issuer])

    FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[1].issuer_profile.id,
                       application_period: application_period, benefit_market_kind: :aca_shop,
                       kind: :health, product_package_kinds: [:single_issuer])

    FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[2].issuer_profile.id,
                       application_period: application_period, benefit_market_kind: :aca_shop,
                       kind: :health, product_package_kinds: [:metal_level])

    FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[3].issuer_profile.id,
                       application_period: application_period, benefit_market_kind: :aca_shop,
                       kind: :health, product_package_kinds: [:single_issuer])

    FactoryGirl.create(:benefit_markets_products_health_products_health_product, issuer_profile_id: issuer_profiles[4].issuer_profile.id,
                       application_period: application_period, benefit_market_kind: :aca_shop,
                       kind: :health, product_package_kinds: [:single_product])

  end

  let!(:site) {FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, site_key: :mhc)}
  let!(:bm) {FactoryGirl.create(:benefit_markets_benefit_market, site: site, site_urn: :cca)}
  let!(:pp_issuer) {FactoryGirl.build(:benefit_markets_products_product_package, package_kind: :single_issuer)}
  let!(:pp_product) {FactoryGirl.build(:benefit_markets_products_product_package, package_kind: :single_product)}
  let!(:pp_metal) {FactoryGirl.build(:benefit_markets_products_product_package, package_kind: :metal_level)}
  let!(:bmc) {FactoryGirl.create(:benefit_markets_benefit_market_catalog, benefit_market: bm, product_packages: [pp_issuer, pp_metal, pp_product])}
  let!(:bmcm) {FactoryGirl.create(:benefit_markets_contribution_models_contribution_model, title: "MA Composite Contribution Model")}
  let!(:bmpm) {FactoryGirl.create(:benefit_markets_pricing_models_pricing_model, name: "MA Composite Price Model")}
  let!(:bmcm2) {FactoryGirl.create(:benefit_markets_contribution_models_contribution_model, title: "MA List Bill Shop Contribution Model")}
  let!(:bmpm2) {FactoryGirl.create(:benefit_markets_pricing_models_pricing_model, name: "MA List Bill Shop Pricing Model")}
  let!(:bmcm3) {FactoryGirl.create(:benefit_markets_contribution_models_contribution_model, title: "MA Shop Simple List Bill Contribution Model")}
  let!(:bmpm3) {FactoryGirl.create(:benefit_markets_pricing_models_pricing_model, name: "MA Shop Simple List Bill Pricing Model")}
  let!(:catalogs) {bm.benefit_market_catalogs}
  let!(:packages) {catalogs.map(&:product_packages).flatten}


  context "before running rake task" do
    it "should have only one catalog" do
      expect(catalogs.count).to eq 1
    end

    it "should have only 3 packages for one catalog" do
      expect(packages.count).to eq 3
    end

    it "should have only 6 products for 3 packages" do
      expect(packages.map(&:products).flatten.count).to eq 6
    end
  end

  context "after running rake task" do
    it "should have two catalogs" do
      invoke_bmc_task
      bm.reload
      expect(catalogs.count).to eq 2
    end

    it "should have only 6 packages for two catalogs" do
      invoke_bmc_task
      bm.reload
      expect(bm.benefit_market_catalogs.map(&:product_packages).flatten.count).to eq 7
    end

    it "should have only 11 products for 6 packages" do
      invoke_bmc_task
      bm.reload
      expect(bm.benefit_market_catalogs.map(&:product_packages).flatten.map(&:products).flatten.count).to eq 11
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end

def invoke_bmc_task
  Rake::Task["load:benefit_market_catalog"].reenable
  Rake::Task["load:benefit_market_catalog"].invoke
end