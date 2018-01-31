FactoryGirl.define do
  factory :employer_profile_no_attestation, class: EmployerProfile do
    organization            { FactoryGirl.build(:organization) }
    entity_kind             "c_corporation"
    sic_code "1111"

    transient do
      employee_roles []
    end

    before :create do |employer_profile, evaluator|
      unless evaluator.employee_roles.blank?
        employer_profile.employee_roles.push *Array.wrap(evaluator.employee_roles)
      end
    end
  end

  factory :employer_profile do
    organization            { FactoryGirl.build(:organization) }
    entity_kind             "c_corporation"
    sic_code "1111"

    transient do
      employee_roles []
      attested true
    end

    trait :with_full_inbox do
      after :create do |employer_profile, evaluator|
        inbox { FactoryGirl.create(:inbox, :with_message, recipient: employer_profile) }
      end
    end

    trait :congress do
      plan_years { [FactoryGirl.build(:plan_year, :with_benefit_group_congress)] }
    end

    before :create do |employer_profile, evaluator|
      unless evaluator.employee_roles.blank?
        employer_profile.employee_roles.push *Array.wrap(evaluator.employee_roles)
      end
    end

    after(:create) do |employer_profile, evaluator|
      if evaluator.attested
        create(:employer_attestation, employer_profile: employer_profile)
      else
        create(:employer_attestation, employer_profile: employer_profile, aasm_state: 'unsubmitted')
      end
    end

    factory :employer_profile_congress,   traits: [:congress]
  end

  factory :registered_employer, class: EmployerProfile do

    organization { FactoryGirl.build(:organization) }
    entity_kind "c_corporation"
    sic_code '1111'
    transient do
      start_on TimeKeeper.date_of_record.beginning_of_month
      plan_year_state 'draft'
      renewal_plan_year_state 'renewing_draft'
      reference_plan_id { FactoryGirl.build(:plan).id }
      elected_plan_ids { FactoryGirl.build(:plan).to_a.map(&:id) }
      with_dental false
      is_conversion false
    end

    factory :employer_with_planyear do
      after(:create) do |employer, evaluator|
        create(:custom_plan_year, employer_profile: employer, start_on: evaluator.start_on, aasm_state: evaluator.plan_year_state, with_dental: evaluator.with_dental)
        create(:employer_attestation, employer_profile: employer)
      end
    end

    factory :employer_with_renewing_planyear do
      after(:create) do |employer, evaluator|
        create(:custom_plan_year, employer_profile: employer, start_on: evaluator.start_on - 1.year, aasm_state: 'active', is_conversion: evaluator.is_conversion)
        create(:custom_plan_year, employer_profile: employer, start_on: evaluator.start_on, aasm_state: evaluator.renewal_plan_year_state, renewing: true, with_dental: evaluator.with_dental)
        create(:employer_attestation, employer_profile: employer)
      end
    end
  end
end
