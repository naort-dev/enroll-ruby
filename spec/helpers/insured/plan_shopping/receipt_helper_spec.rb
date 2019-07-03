require "rails_helper"

RSpec.describe Insured::PlanShopping::ReceiptHelper, :type => :helper do
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :with_family) }
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let(:family) { person.primary_family }
  let(:household) { family.active_household }
  let(:individual_plans) { FactoryBot.create_list(:plan, 5, :with_premium_tables, market: 'individual') }

  describe "Carrier with payment options" do
    let(:carrier_profile) { FactoryBot.create(:carrier_profile, legal_name: 'Kaiser') }
    let(:plan) { FactoryBot.create(:plan, carrier_profile: carrier_profile) }

    HbxEnrollment::Kinds.each do |market|
      context "#{market} market" do
        let!(:hbx_enrollment) do
          FactoryBot.create(:hbx_enrollment,
                            :with_enrollment_members,
                            enrollment_members: family.family_members,
                            household: household,
                            plan: plan,
                            effective_on: TimeKeeper.date_of_record.beginning_of_year,
                            kind: market)
        end

        before :each do
          assign(:enrollment, hbx_enrollment)
        end
        it "returns #{market == 'individual'} for #{market} + Kaiser" do
          allow(helper).to receive(:has_any_previous_kaiser_enrollments?).and_return(false) if market == ('individual' || 'coverall')
          expect(helper.show_pay_now?).to eq market == 'individual'
        end
      end
    end
  end

  describe "Carrier with NO payment options" do
    let(:carrier_profile) { FactoryBot.create(:carrier_profile, legal_name: 'ANY OTHER') }
    let(:plan) { FactoryBot.create(:plan, carrier_profile: carrier_profile) }
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        household: household,
                        plan: plan,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end
    before :each do
      assign(:enrollment, hbx_enrollment)
    end
    it "returns false for not Kaiser" do
      expect(helper.show_pay_now?).to eq false
    end
  end

  describe "Check family has Kaiser enrollments or not" do
    let(:carrier_profile) { FactoryBot.create(:carrier_profile, legal_name: 'Kaiser') }
    let(:plan) { FactoryBot.create(:plan, carrier_profile: carrier_profile) }
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        household: household,
                        plan: plan,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.month,
                        kind: 'individual')
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        household: household,
                        plan: plan,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end
    before :each do
      assign(:enrollment, hbx_enrollment)
    end

    it 'return true if household has kaiser enrollments in current benefit coverage period' do
      expect(helper.has_any_previous_kaiser_enrollments?).to eq true
    end

    it 'return false if household has kaiser enrollments in current benefit coverage period' do
      carrier_profile.update_attributes(legal_name: 'Something')
      expect(helper.has_any_previous_kaiser_enrollments?).to eq false
    end

    it 'return false if household has kaiser enrollments in a previous benefit coverage period year' do
      hbx_enrollment1.update_attributes(effective_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_any_previous_kaiser_enrollments?).to eq false
    end

    it 'return false if household had no kaiser enrollments in current benefit coverage period' do
      carrier_profile.update_attributes(legal_name: 'Something')
      expect(helper.has_any_previous_kaiser_enrollments?).to eq false
    end
  end

  describe "Whether family has break in covergae enrollments" do
    let(:carrier_profile) { FactoryBot.create(:carrier_profile, legal_name: 'Kaiser') }
    let(:plan) { FactoryBot.create(:plan, carrier_profile: carrier_profile) }
    let!(:hbx_enrollment) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        household: household,
                        plan: plan,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.month,
                        kind: 'individual')
    end

    let!(:hbx_enrollment1) do
      FactoryBot.create(:hbx_enrollment,
                        :with_enrollment_members,
                        enrollment_members: family.family_members,
                        household: household,
                        plan: plan,
                        effective_on: TimeKeeper.date_of_record.beginning_of_year,
                        kind: 'individual')
    end

    before :each do
      assign(:enrollment, hbx_enrollment)
    end

    it 'should return true if there is a break in coverage' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year + 10.days)
      expect(helper.has_break_in_coverage_enrollments?).to eq true
    end

    it 'should return false if there is a no break in coverage' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year + 1.month)
      expect(helper.has_break_in_coverage_enrollments?).to eq false
    end

    it 'should return false if there is a terminated enrollment in previous year' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.last_year)
      expect(helper.has_break_in_coverage_enrollments?).to eq false
    end

    it 'should return false if there is a break in coverage less than 1 day' do
      hbx_enrollment1.update_attributes(aasm_state: 'coverage_terminated', terminated_on: TimeKeeper.date_of_record.beginning_of_year)
      hbx_enrollment.update_attributes(effective_on: TimeKeeper.date_of_record.beginning_of_year + 1.day)
      expect(helper.has_break_in_coverage_enrollments?).to eq false
    end
  end
end
