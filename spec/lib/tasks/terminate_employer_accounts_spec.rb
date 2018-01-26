require 'rails_helper'
require 'rake'
require 'stringio'

describe 'terminating employer active plan year & enrollments', :dbclean => :around_each do
  describe 'migrations:terminate_employer_account' do

    let(:benefit_group) { FactoryGirl.create(:benefit_group)}
    let(:active_plan_year)  { FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.next_month.next_month.beginning_of_month - 1.year, end_on: TimeKeeper.date_of_record.next_month.end_of_month, aasm_state: 'active',benefit_groups:[benefit_group]) }
    let(:employer_profile)     { FactoryGirl.build(:employer_profile, plan_years: [active_plan_year]) }
    let(:organization) { FactoryGirl.create(:organization,employer_profile:employer_profile)}
    let(:family) { FactoryGirl.build(:family, :with_primary_family_member)}
    let(:enrollment) { FactoryGirl.build(:hbx_enrollment, household: family.active_household)}
    let(:employee_role) { FactoryGirl.create(:employee_role) }
    let(:ce) { FactoryGirl.create(:census_employee, employer_profile: employer_profile, employee_role_id: employee_role.id) }
    let!(:params) { {recipient: ce.employee_role, event_object: active_plan_year, notice_event: "notify_employee_when_employer_requests_advance_termination"} }
    let(:fein) { organization.fein }
    let(:end_on) { TimeKeeper.date_of_record.end_of_month.strftime('%m/%d/%Y') }
    let(:termination_date) { TimeKeeper.date_of_record.strftime('%m/%d/%Y') }

    before do
      $stdout = StringIO.new
      load File.expand_path("#{Rails.root}/lib/tasks/migrations/terminate_employer_accounts.rake", __FILE__)
      Rake::Task.define_task(:environment)
      enrollment.update_attributes(benefit_group_id: benefit_group.id, aasm_state:'coverage_selected')
      Rake::Task["migrations:terminate_employer_account"].invoke(fein,end_on,termination_date,"false")
    end

    after(:all) do
      $stdout = STDOUT
    end

    it 'should terminate plan year & enrollment and update plan year & enrollment end_on and terminated date' do
      active_plan_year.reload
      enrollment.reload
      expect(active_plan_year.end_on).to eq TimeKeeper.date_of_record.end_of_month
      expect(active_plan_year.terminated_on).to eq TimeKeeper.date_of_record
      expect(active_plan_year.aasm_state).to eq "terminated"

      expect(enrollment.terminated_on).to eq TimeKeeper.date_of_record.end_of_month
      expect(enrollment.termination_submitted_on).to eq TimeKeeper.date_of_record
      expect(enrollment.aasm_state).to eq "coverage_terminated"
    end

    it 'should not terminate published plan year' do
      active_plan_year.update_attribute(:aasm_state,'published')
      active_plan_year.reload
      expect(active_plan_year.end_on).to eq active_plan_year.end_on
      expect(active_plan_year.terminated_on).to eq nil
      expect(active_plan_year.aasm_state).to eq "published"
    end

    it 'should send notification when we pass true in generate_termination_notice attribute' do
      expect_any_instance_of(Observers::Observer).not_to receive(:trigger_notice).with(params).exactly(employer_profile.census_employees.active.size).times
      Rake::Task["migrations:terminate_employer_account"].reenable
      Rake::Task["migrations:terminate_employer_account"].invoke(fein,end_on,termination_date,"true")
      expect($stdout.string).to match("Notification generated for employer\n")
    end

    it 'should not send notification when we pass false in generate_termination_notice attribute' do
      expect_any_instance_of(Observers::Observer).not_to receive(:trigger_notice)
      Rake::Task["migrations:terminate_employer_account"].reenable
      Rake::Task["migrations:terminate_employer_account"].invoke(fein,end_on,termination_date,"false")
      expect($stdout.string).not_to match("Notification generated for\n")
    end

  end
end
