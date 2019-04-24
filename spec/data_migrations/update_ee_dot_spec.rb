require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_ee_dot")

describe UpdateEeDot, dbclean: :after_each do

  let(:given_task_name) { "update_ee_dot" }
  let(:terminated_on) { TimeKeeper.date_of_record - 20.days }
  subject { UpdateEeDot.new(given_task_name, double(:current_scope => nil)) }

   after :each do
     ["id", "employment_terminated_on", "coverage_terminated_on"].each do |env_variable|
       ENV[env_variable] = nil
     end
   end

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating termination date for an Employee" do

    let(:employer_profile) { census_employee.employer_profile}
    let(:census_employee) { FactoryBot.create(:census_employee, coverage_terminated_on:TimeKeeper.date_of_record)}

    before(:each) do
      ENV["id"] = census_employee.id
      ENV["employment_terminated_on"] = terminated_on.to_s
      ENV["coverage_terminated_on"] = ''
    end

    it "should update date of termination" do
      subject.migrate
      census_employee.reload
      expect(census_employee.employment_terminated_on).to eq (terminated_on)
    end
  end

  describe "updating coverage termination date for an Employee" do

    let(:employer_profile) { census_employee.employer_profile }
    let(:census_employee) { FactoryBot.create(:census_employee)}

    before(:each) do
      ENV["id"] = census_employee.id
      ENV["coverage_terminated_on"] = terminated_on.to_s
      ENV["employment_terminated_on"] = ''
    end

    it "should update date of coverage termination" do
      subject.migrate
      census_employee.reload
      expect(census_employee.coverage_terminated_on).to eq (terminated_on)
    end
  end
end
