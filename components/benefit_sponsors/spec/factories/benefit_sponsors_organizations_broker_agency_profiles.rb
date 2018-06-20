FactoryGirl.define do
  factory :benefit_sponsors_organizations_broker_agency_profile, class: 'BenefitSponsors::Organizations::BrokerAgencyProfile' do
    organization { FactoryGirl.build(:benefit_sponsors_organizations_general_organization, :with_site) }

    market_kind :shop
    corporate_npn "0989898981"
    ach_routing_number '123456789'
    ach_account_number '9999999999999999'
    transient do
      office_locations_count 1
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end
  end
end
