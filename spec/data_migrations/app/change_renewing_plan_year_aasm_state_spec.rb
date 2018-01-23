require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_renewing_plan_year_aasm_state")


describe ChangeRenewingPlanYearAasmState, dbclean: :after_each do

  let(:given_task_name) { "change_renewing_plan_year_aasm_state" }
  let!(:rating_area) { RatingArea.first || FactoryGirl.create(:rating_area)  }
  subject { ChangeRenewingPlanYearAasmState.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating aasm_state of the renewing plan year", dbclean: :after_each do
    let(:benefit_group) { FactoryGirl.create(:benefit_group) }
    let(:active_plan_year){ FactoryGirl.build(:plan_year,start_on:TimeKeeper.date_of_record.next_month.beginning_of_month - 1.year, end_on:TimeKeeper.date_of_record.end_of_month,aasm_state: "active",benefit_groups:[benefit_group]) }
    let(:plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_publish_pending") }
    let(:employer_profile){ FactoryGirl.build(:employer_profile, plan_years: [active_plan_year,plan_year]) }
    let(:organization)  {FactoryGirl.create(:organization,employer_profile:employer_profile)}
#    Somehow this damages the loading order resulting in the census employee not being picked up correctly.
#    let(:rating_area) { create(:rating_area, county_name: organization.primary_office_location.address.county, zip_code: organization.primary_office_location.address.zip)}
    let(:benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group)}
    let!(:renewal_benefit_group){ FactoryGirl.build(:benefit_group, plan_year: plan_year) }
    let(:renewal_benefit_group_assignment) { FactoryGirl.build(:benefit_group_assignment, benefit_group: renewal_benefit_group)}
    let(:census_employee) { FactoryGirl.create(:census_employee,employer_profile: employer_profile,:benefit_group_assignments => [benefit_group_assignment,renewal_benefit_group_assignment]) }

    before(:each) do
      allow(ENV).to receive(:[]).with("fein").and_return(organization.fein)
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return(plan_year.start_on)
    end

    it "should update aasm_state of plan year" do
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "renewing_enrolling"
    end

    it "should not should update aasm_state of plan year when ENV['plan_year_start_on'] is empty" do
      allow(ENV).to receive(:[]).with("plan_year_start_on").and_return('')
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "renewing_publish_pending"
    end

    ["renewing_publish_pending", "renewing_application_ineligible"].each do |plan_year_state|
      it "should update aasm_state of plan year" do
        plan_year.update_attributes(aasm_state: plan_year_state)
        subject.migrate
        plan_year.reload
        expect(plan_year.aasm_state).to eq "renewing_enrolling"
      end
    end

    it "should update aasm_state of plan year to renewing_enrolled when OE closed and has valid enrollment" do
      allow_any_instance_of(PlanYear).to receive(:is_enrollment_valid?).and_return(true)
      allow_any_instance_of(PlanYear).to receive(:is_open_enrollment_closed?).and_return(true)
      allow_any_instance_of(PlanYear).to receive(:may_activate?).and_return(false)
      census_employee.reload
      subject.migrate
      plan_year.reload
      expect(plan_year.aasm_state).to eq "renewing_enrolled"
    end

    it "should update aasm_state of plan year to active if plan year can be activated" do
      allow_any_instance_of(PlanYear).to receive(:is_enrollment_valid?).and_return(true)
      allow_any_instance_of(PlanYear).to receive(:is_open_enrollment_closed?).and_return(true)
      allow_any_instance_of(PlanYear).to receive(:can_be_activated?).and_return(true)
      census_employee.reload
      subject.migrate
      plan_year.reload
      puts plan_year.inspect
      expect(plan_year.aasm_state).to eq "active"
    end
  end
end
