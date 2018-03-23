FactoryGirl.define do
  factory :benefit_markets_benefit_market, class: 'BenefitMarkets::BenefitMarket' do
    kind :aca_shop
    title "DC Health Link SHOP Market"
    description "Health Insurance Marketplace for District Employers and Employees"

    trait :with_site do
      after :build do |benefit_market, evaluator|
        build(:sponsored_benefits_site, :with_owner_exempt_organization, benefit_markets: [benefit_market])
      end
    end

    trait :with_benefit_catalog do
      after :build do |benefit_market, evaluator|
        benefit_market.benefit_catalogs << build(:benefit_catalogs_benefit_catalog)
      end
    end

  end
end
