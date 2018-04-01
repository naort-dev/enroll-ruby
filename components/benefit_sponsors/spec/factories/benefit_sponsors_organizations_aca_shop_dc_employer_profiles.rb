FactoryGirl.define do
  factory :benefit_sponsors_organizations_aca_shop_dc_employer_profile, class: 'BenefitSponsors::Organizations::AcaShopDcEmployerProfile' do
    entity_kind :c_corporation

    is_benefit_sponsorship_eligible true

    transient do
      office_locations_count 1
    end

    after(:build) do |office_locations_count, evaluator|
      build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end


  end
end
