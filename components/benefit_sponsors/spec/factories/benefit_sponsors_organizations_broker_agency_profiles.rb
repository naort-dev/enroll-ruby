FactoryBot.define do
  factory :benefit_sponsors_organizations_broker_agency_profile, class: 'BenefitSponsors::Organizations::BrokerAgencyProfile' do

    market_kind { is_shop_market_enabled? ? :shop : :individual }
    corporate_npn { "0989898981" }
    ach_routing_number { '123456789' }
    ach_account_number { '9999999999999999' }
    association :primary_broker_role, factory: :broker_role
    transient do
      legal_name { nil }
      office_locations_count { 1 }
      assigned_site { nil }
    end

    after(:build) do |profile, evaluator|
      profile.office_locations << build_list(:benefit_sponsors_locations_office_location, evaluator.office_locations_count, :primary)
    end

    after(:build) do |profile, evaluator|
      if profile.organization.blank?
        if evaluator.assigned_site
          profile.organization = FactoryBot.build(:benefit_sponsors_organizations_general_organization, legal_name: evaluator.legal_name, site: evaluator.assigned_site )
        else
          profile.organization = FactoryBot.build(:benefit_sponsors_organizations_general_organization, :with_site)
        end
      end
    end

    after(:build) do |profile, evaluator|
      broker_role = profile.primary_broker_role
      if broker_role.present? && broker_role.benefit_sponsors_broker_agency_profile_id.blank?
        broker_role.benefit_sponsors_broker_agency_profile_id = profile.id
        broker_role.save! && profile.save!
      end
    end
  end
end
