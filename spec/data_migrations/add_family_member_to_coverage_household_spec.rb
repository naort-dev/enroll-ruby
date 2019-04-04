require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_family_member_to_coverage_household")

describe AddFamilyMemberToCoverageHousehold, dbclean: :after_each do

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  let(:given_task_name) { "add_family_member_to_coverage_household" }
  subject { AddFamilyMemberToCoverageHousehold.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "add family member to coverage household", dbclean: :after_each do

    let!(:person) { FactoryBot.create(:person, :with_family, :with_ssn) }
    let!(:dependent) { FactoryBot.create(:person) }
    let!(:family_member) { FactoryBot.create(:family_member, family: person.primary_family ,person: dependent)}
    let!(:coverage_household_member) { coverage_household.coverage_household_members.new(:family_member_id => family_member.id) }
    let(:primary_family){person.primary_family}
    let(:coverage_household){person.primary_family.active_household.immediate_family_coverage_household}
    let(:fm_env_support) {{primary_hbx_id: person.hbx_id}}

    it "should add a family member to immediate family coverage household" do
      with_modified_env fm_env_support do 
        expect(coverage_household.coverage_household_members.size).to eq 2
        chm = coverage_household.coverage_household_members[1]
        chm.destroy!
        expect(coverage_household.coverage_household_members.size).to eq 1
        subject.migrate
        primary_family.active_household.reload
        expect(coverage_household.coverage_household_members.size).to eq 1
      end
    end

    it "should add a primary applicant to immediate family coverage household" do
      with_modified_env fm_env_support do 
        expect(coverage_household.coverage_household_members.size).to eq 2
        chm = coverage_household.coverage_household_members[0]
        chm.destroy!
        expect(coverage_household.coverage_household_members.size).to eq 1
        subject.migrate
        primary_family.active_household.reload
        expect(coverage_household.coverage_household_members.size).to eq 1
      end
    end
  end
end
