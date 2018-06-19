FactoryGirl.define do
  factory :benefit_sponsors_benefit_sponsorship, class: 'BenefitSponsors::BenefitSponsorships::BenefitSponsorship' do

    source_kind   :self_serve

    initialize_with   {
        site  = create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca)
        organization  = build(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site)
        profile = organization.employer_profile
        profile.add_benefit_sponsorship
    }

    trait :with_benefit_market do
      benefit_market { FactoryGirl.build :benefit_markets_benefit_market}
    end

    trait :with_organization_dc_profile do
      after :build do |benefit_sponsorship, evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_dc_employer_profile, organization: benefit_sponsorship.organization)
        benefit_sponsorship.profile = profile
      end
    end

    trait :with_organization_cca_profile do
      after :build do |benefit_sponsorship, evaluator|
        profile = build(:benefit_sponsors_organizations_aca_shop_cca_employer_profile, organization: benefit_sponsorship.organization)
        benefit_sponsorship.profile = profile
      end
    end

    trait :with_full_package do
      after :build do |benefit_sponsorship, evaluator|

      end
    end

    trait :with_market_profile do
      # we have to update the factory create instead of build
      before(:create) do |benefit_sponsorship, evaluator|

      end
    end

    trait :with_initial_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_sponsorship.benefit_applications = [FactoryGirl.create(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          aasm_state: :active
        )]
        benefit_sponsorship.benefit_applications.map(&:save) # TODO
      end
    end

    trait :with_renewal_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryGirl.create(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          :with_predecessor_application,
          :benefit_sponsorship => benefit_sponsorship,
          :aasm_state => :enrollment_open
        )

        benefit_sponsorship.benefit_applications = [benefit_application, benefit_application.predecessor_application]
        benefit_sponsorship.benefit_applications.map(&:save) # TODO
      end
    end

    trait :with_expired_and_active_benefit_application do
      after :build do |benefit_sponsorship, evaluator|
        benefit_application = FactoryGirl.create(:benefit_sponsors_benefit_application,
          :with_benefit_package,
          :with_active,
          :with_predecessor_expired_application,
          :benefit_sponsorship => benefit_sponsorship
        )

        benefit_sponsorship.benefit_applications = [benefit_application, benefit_application.predecessor_application]
        benefit_sponsorship.benefit_applications.map(&:save) # TODO
      end
    end

    trait :with_broker_agency_account do
      after :build do |benefit_sponsorship, evaluator|
        broker_agency_account = FactoryGirl.build :benefit_sponsors_accounts_broker_agency_account
        benefit_sponsorship.broker_agency_accounts= [broker_agency_account]
      end
    end

  end
end
