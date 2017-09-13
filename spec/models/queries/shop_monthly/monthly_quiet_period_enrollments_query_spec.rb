require "rails_helper"

describe "a monthly inital employer quiet period enrollments query" do
  describe "given an employer who has completed their first open enrollment" do
    describe "with employees who have made the following plan selections:
       - employee A has purchased:
         - One health enrollment during OE (Enrollment 1)
       - employee B has purchased:
         - One health enrollment during Quiet Period(Enrollment 2)
         - One health waiver during Quiet Period(Enrollment 3)
       - employee C has purchased:
         - One health enrollment during Quiet Period(Enrollment 4)
         - One dental enrollment during Quiet Period(Enrollment 5)
         - Then another health enrollment outside Quiet Period(Enrollment 6)
    " do

      let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }

      let(:initial_employer) {
        FactoryGirl.create(:employer_with_planyear, start_on: effective_on, plan_year_state: 'enrolled')
      }

      let(:plan_year) {
        initial_employer.published_plan_year
      }

      let(:quiet_period_end_on) {
        Settings.aca.shop_market.initial_application.quiet_period_end_on
      }

      let(:quiet_period_end_date) {
        prev_month_begin = plan_year.start_on.prev_month
        Date.new(prev_month_begin.year, prev_month_begin.month, quiet_period_end_on)
      }

      let(:initial_employees) {
        FactoryGirl.create_list(:census_employee_with_active_assignment, 3, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: initial_employer,
          benefit_group: plan_year.benefit_groups.first)
      }

      let(:employee_A) {
        ce = initial_employees[0]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_1) {
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }

      let(:employee_B) {
        ce = initial_employees[1]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_2) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day)
      }

      let!(:enrollment_3) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day, status: 'inactive', parent: enrollment_2)
      }

      let(:employee_C) {
        ce = initial_employees[2]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_4) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day)
      }

      let!(:enrollment_5) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day, coverage_kind: 'dental')
      }

      let!(:enrollment_6) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.next_day)
      }

   
      it "does not include enrollment 1" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_1.hbx_id)
      end

      it "includes enrollment 2" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_2.hbx_id)
      end

      it "does not include enrollment 3" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_3.hbx_id)
      end

      it "includes enrollment 4" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_4.hbx_id)
      end

      it "includes enrollment 5" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).to include(enrollment_5.hbx_id)
      end

      it "does not include enrollment 6" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, ['coverage_selected'])
        expect(result).not_to include(enrollment_6.hbx_id)
      end
    end

    describe "with employees who have made the following plan terminations:
       - employee A has purchased:
         - One health enrollment during OE (Enrollment 1)
       - employee B has purchased:
         - One health enrollment during Quiet Period(Enrollment 2)
         - One health waiver during Quiet Period(Enrollment 3)
       - employee C has purchased:
         - One health enrollment during OE(Enrollment 4)
         - One dental enrollment during OE(Enrollment 5)
         - One health waiver during Quiet Period(Enrollment 6)
         - One dental waiver during Quiet Period(Enrollment 7)
         - Then another health enrollment outside Quiet Period(Enrollment 8)
         - Then another dental enrollment outside Quiet Period(Enrollment 9)
    " do

      let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }

      let(:initial_employer) {
        FactoryGirl.create(:employer_with_planyear, start_on: effective_on, plan_year_state: 'enrolled')
      }

      let(:plan_year) {
        initial_employer.published_plan_year
      }

      let(:quiet_period_end_on) {
        Settings.aca.shop_market.initial_application.quiet_period_end_on
      }

      let(:quiet_period_end_date) {
        prev_month_begin = plan_year.start_on.prev_month
        Date.new(prev_month_begin.year, prev_month_begin.month, quiet_period_end_on)
      }

      let(:initial_employees) {
        FactoryGirl.create_list(:census_employee_with_active_assignment, 3, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: initial_employer,
          benefit_group: plan_year.benefit_groups.first)
      }

      let(:employee_A) {
        ce = initial_employees[0]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_1) {
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }

      let(:employee_B) {
        ce = initial_employees[1]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_2) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day)
      }

      let!(:enrollment_3) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: quiet_period_end_date.prev_day, status: 'inactive', parent: enrollment_2)
      }

      let(:employee_C) {
        ce = initial_employees[2]
        create_person(ce, initial_employer)
      }

      let!(:enrollment_4) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day)
      }

      let!(:enrollment_5) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_A,
                            submitted_at: plan_year.open_enrollment_end_on - 10.day, coverage_kind: 'dental')
      }

      let!(:enrollment_6) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day, status: 'inactive', parent: enrollment_4) 
      }

      let!(:enrollment_7) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.prev_day, coverage_kind: 'dental', status: 'inactive', parent: enrollment_5)
      }

      let!(:enrollment_8) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.next_day)
      }

      let!(:enrollment_9) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: quiet_period_end_date.next_day, coverage_kind: 'dental')
      }

      let(:term_statuses){ %w(coverage_terminated coverage_canceled coverage_termination_pending) }

   
      it "does not include enrollment 1" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, [])
        expect(result).not_to include(enrollment_1.hbx_id)
      end

      it "includes enrollment 2" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).to include(enrollment_2.hbx_id)
      end

      it "does not include enrollment 3" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_3.hbx_id)
      end

      it "includes enrollment 4" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).to include(enrollment_4.hbx_id)
      end

      it "includes enrollment 5" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).to include(enrollment_5.hbx_id)
      end

      it "does not include enrollment 6" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_6.hbx_id)
      end

      it "does not include enrollment 7" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_7.hbx_id)
      end

      it "does not include enrollment 8" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_8.hbx_id)
      end

      it "does not include enrollment 8" do
        result = Queries::NamedPolicyQueries.shop_quiet_period_enrollments(effective_on, term_statuses)
        expect(result).not_to include(enrollment_9.hbx_id)
      end
    end
  end

  def create_person(ce, employer_profile)
    person = FactoryGirl.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryGirl.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
    employee_role
  end

  def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health', parent: nil)
    benefit_group = benefit_group_assignment.benefit_group
    enrollment = FactoryGirl.create(:hbx_enrollment,:with_enrollment_members,
      enrollment_members: [family.primary_applicant],
      household: family.active_household,
      coverage_kind: coverage_kind,
      effective_on: effective_date || benefit_group.start_on,
      enrollment_kind: enrollment_kind,
      kind: "employer_sponsored",
      submitted_at: submitted_at,
      benefit_group_id: benefit_group.id,
      employee_role_id: employee_role.id,
      benefit_group_assignment_id: benefit_group_assignment.id,
      plan_id: benefit_group.reference_plan.id,
      aasm_state: status
    )

    if enrollment.coverage_selected? || enrollment.inactive?
      enrollment.workflow_state_transitions.create(from_state: 'shopping', to_state: status, transition_at: submitted_at)
    end

    if enrollment.inactive?
      parent.update(aasm_state: 'coverage_canceled')
      parent.workflow_state_transitions.create(from_state: parent.aasm_state, to_state: 'coverage_canceled', transition_at: submitted_at)
    end

    enrollment
  end
end
