require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_new_hire_rule")

describe ChangeNewHireRule do

  let(:given_task_name) { "change_new_hire_rule" }
  subject { ChangeNewHireRule.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing new hire rule" do

    context " changing effective on kind" do
      let(:organization) { FactoryBot.create(:organization)}
      let(:benefit_group)     { FactoryBot.build(:benefit_group, effective_on_kind: "date_of_hire")}
      let(:plan_year)         { FactoryBot.build(:plan_year, benefit_groups: [benefit_group]) }
      let!(:employer_profile)  { FactoryBot.create(:employer_profile, organization: organization, plan_years: [plan_year]) }

      it "will change the effective on kind for the benefit group from date_of_hire to first_of_month" do
        ClimateControl.modify fein: organization.fein, plan_year_state: plan_year.aasm_state do
          subject.migrate
          benefit_group.reload
          expect(benefit_group.effective_on_kind).to eq "first_of_month"
        end
      end
    end
  end

end
