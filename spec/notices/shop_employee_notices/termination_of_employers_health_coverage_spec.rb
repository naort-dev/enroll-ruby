require 'rails_helper'

RSpec.describe ShopEmployeeNotices::TerminationOfEmployersHealthCoverage, :dbclean => :after_each do
  let!(:hbx_profile) { FactoryBot.create(:hbx_profile) }
  let!(:benefit_sponsorship) { FactoryBot.create(:benefit_sponsorship, hbx_profile: hbx_profile) }
  let(:plan) { FactoryBot.create(:plan) }
  let(:plan2) { FactoryBot.create(:plan) }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:employer_profile){ create :employer_profile, aasm_state: "active"}
  let!(:person){ create :person}
  let(:oe_start_on) { Settings.aca.individual_market.open_enrollment.start_on }
  let(:oe_end_on) { Settings.aca.individual_market.open_enrollment.end_on }

  let!(:current_benefit_coverage_period) {
      FactoryBot.create(:benefit_coverage_period,
      start_on: Date.new(oe_end_on.year, 1, 1),
      end_on: Date.new(oe_end_on.year, 12, 31),
      open_enrollment_start_on: Settings.aca.individual_market.open_enrollment.start_on,
      open_enrollment_end_on:  Settings.aca.individual_market.open_enrollment.end_on,
      title: "Individual Market Benefits 2018", benefit_sponsorship: benefit_sponsorship)
    }

  let!(:renewal_benefit_coverage_period) {
      FactoryBot.create(:benefit_coverage_period,
      start_on: current_benefit_coverage_period.start_on + 1.year,
      end_on: current_benefit_coverage_period.end_on + 1.year,
      open_enrollment_start_on: current_benefit_coverage_period.open_enrollment_start_on+1.year,
      open_enrollment_end_on: current_benefit_coverage_period.open_enrollment_end_on+1.year,
      benefit_sponsorship: benefit_sponsorship)
        }

  let!(:plan_year) { FactoryBot.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'enrolled' ) }
  let!(:active_benefit_group) { FactoryBot.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:benefit_group_assignment)  { FactoryBot.create(:benefit_group_assignment, benefit_group: active_benefit_group, census_employee: census_employee) }
  let(:employee_role) {FactoryBot.create(:employee_role, person: person, employer_profile: employer_profile)}
  let(:census_employee) { FactoryBot.create(:census_employee, employee_role_id: employee_role.id, employer_profile_id: employer_profile.id) }
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>"Notice to EEs that ER’s plan year will not be written",
                            :notice_template => 'notices/shop_employee_notices/termination_of_employers_health_coverage',
                            :notice_builder => 'ShopEmployeeNotices::TerminationOfEmployersHealthCoverage',
                            :event_name => 'notice_to_ee_that_er_plan_year_will_not_be_written',
                            :mpi_indicator => 'SHOP_D064',
                            :title => "Termination of Employer’s Health Coverage Offered through DC Health Link"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  before do
    @employee_notice = ShopEmployeeNotices::TerminationOfEmployersHealthCoverage.new(census_employee, valid_params)
  end

  describe "New" do

    context "valid params" do
      it "should initialze" do
        expect{ShopEmployeeNotices::TerminationOfEmployersHealthCoverage.new(census_employee, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{ShopEmployeeNotices::TerminationOfEmployersHealthCoverage.new(census_employee, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do

    it "should build notice with all necessory info" do
      @employee_notice.build
      expect(@employee_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employee_notice.notice.employer_name).to eq employer_profile.organization.legal_name
    end
  end

  describe "append data" do

    before do
      @employee_notice.append_data
    end

    it "should append data" do
      expect(@employee_notice.notice.plan_year.start_on).to eq plan_year.start_on
    end

    context "with current IVL Open Enrollment(2018)" do

      before do
        TimeKeeper.set_date_of_record_unprotected!(current_benefit_coverage_period.open_enrollment_start_on.next_day)
        @employee_notice.append_data
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      it "should append current IVL OE date(2018)" do
        expect(@employee_notice.notice.enrollment.ivl_open_enrollment_start_on).to eq current_benefit_coverage_period.open_enrollment_start_on
        expect(@employee_notice.notice.enrollment.ivl_open_enrollment_end_on).to eq current_benefit_coverage_period.open_enrollment_end_on
      end
    end

    context "after current IVL OE closed(2018)" do

      before do
        TimeKeeper.set_date_of_record_unprotected!(current_benefit_coverage_period.open_enrollment_end_on.next_day)
      end

      after do
        TimeKeeper.set_date_of_record_unprotected!(Date.today)
      end

      it "should append next year IVL OE dates(2019)" do
        @employee_notice.append_data
        expect(@employee_notice.notice.enrollment.ivl_open_enrollment_start_on).to eq renewal_benefit_coverage_period.open_enrollment_start_on
        expect(@employee_notice.notice.enrollment.ivl_open_enrollment_end_on).to eq renewal_benefit_coverage_period.open_enrollment_end_on
      end
    end
  end

  describe "Rendering termination_of_employers_health_coverage template and generate pdf" do

    before do
      allow(census_employee.employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end

    it "should match event_name" do
      expect(@employee_notice.event_name).to eq "notice_to_ee_that_er_plan_year_will_not_be_written"
    end

    it "should render termination_of_employers_health_coverage" do
      expect(@employee_notice.template).to eq "notices/shop_employee_notices/termination_of_employers_health_coverage"
    end

    it "should match mpi_indicator" do
      expect(@employee_notice.mpi_indicator).to eq "SHOP_D064"
    end

    it "should generate pdf" do
      @employee_notice.build
      @employee_notice.append_data
      file = @employee_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end 
end
