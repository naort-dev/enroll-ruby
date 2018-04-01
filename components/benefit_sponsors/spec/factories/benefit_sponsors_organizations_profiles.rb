FactoryGirl.define do
  factory :benefit_sponsors_organizations_profile, class: 'BenefitSponsors::Organizations::Profile' do
    
    transient do
      office_locations_count 1
    end

    after(:build) do |office_locations_count, evaluator|
      create_list(:office_location, evaluator.office_locations_count, :primary, office_location: office_location)
    end
  end
end
