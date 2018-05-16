FactoryGirl.define do
  factory :benefit_markets_locations_service_area, class: 'BenefitMarkets::Locations::ServiceArea' do

    active_year TimeKeeper.date_of_record.year
    issuer_provided_code "issuer name"
    issuer_profile_id BenefitSponsors::Organizations::IssuerProfile.new.id
    # Both of these would never happen at the same time
    county_zip_ids [FactoryGirl.create(:benefit_markets_locations_county_zip).id.to_s]
    # covered_states ["MA"]

  end
end
