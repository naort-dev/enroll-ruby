require "rails_helper"

describe "a monthly shop renewal termination query", dbclean: :after_each do
# TODO   app/models/subscribers/shop_renewal_transmission_authorized.rb
 #  Fix specs when shop_monthly_terminations scenario fixed in app/models/subscribers/shop_renewal_transmission_authorized.rb
  describe "given a renewing employer who has completed their open enrollment" do
    describe "with employees who have made the following plan selections:
       - employee A has purchased:
         - Health Coverage in the previous plan year (Enrollment 1)
         - One health enrollment (Enrollment 2)
       - employee B has purchased:
         - A health enrollment in the previous plan year (Enrollment 3)
         - One health enrollment (Enrollment 4)
         - Then a health waiver (Enrollment 5)
       - employee C has purchased:       
         - A health enrollment in the previous plan year (Enrollment 6)
         - One dental enrollment (Enrollment 7)
         - Then a health waiver (Enrollment 8)
       - employee D has purchased:       
         - A health enrollment in the previous plan year (Enrollment 9)
         - One dental enrollment (Enrollment 10)
         - Then a health waiver (Enrollment 11)
         - Then one health enrollment (Enrollment 12)
    " do

      let(:effective_on) { TimeKeeper.date_of_record.end_of_month.next_day }

      let(:renewing_employer) {
        FactoryBot.create(:employer_with_renewing_planyear, start_on: effective_on, renewal_plan_year_state: 'renewing_enrolled')
      }

      let(:renewing_employees) {
        FactoryBot.create_list(:census_employee_with_active_and_renewal_assignment, 4, :old_case, hired_on: (TimeKeeper.date_of_record - 2.years), employer_profile: renewing_employer, 
          benefit_group: renewing_employer.active_plan_year.benefit_groups.first, 
          renewal_benefit_group: renewing_employer.renewing_plan_year.benefit_groups.first)
      }

      let(:employee_A) {
        ce = renewing_employees[0]
        create_person(ce, renewing_employer)
      }

      let!(:enrollment_1) {      
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.active_benefit_group_assignment, employee_role: employee_A, submitted_at: effective_on.prev_year) 
      }

      let!(:enrollment_2) {
        create_enrollment(family: employee_A.person.primary_family, benefit_group_assignment: employee_A.census_employee.renewal_benefit_group_assignment, employee_role: employee_A, submitted_at: effective_on - 20.days, status: 'auto_renewing') 
      }

      let(:employee_B) {
        ce = renewing_employees[1]
        create_person(ce, renewing_employer)
      }

      let!(:enrollment_3) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.active_benefit_group_assignment, employee_role: employee_B, submitted_at: effective_on.prev_year) 
      }

      let!(:enrollment_4) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.renewal_benefit_group_assignment, employee_role: employee_B, submitted_at: effective_on - 24.days, status: 'coverage_canceled') 
      }

      let!(:enrollment_5) {
        create_enrollment(family: employee_B.person.primary_family, benefit_group_assignment: employee_B.census_employee.renewal_benefit_group_assignment, employee_role: employee_B, submitted_at: effective_on - 22.days, status: 'inactive') 
      }

      let(:employee_C) {
        ce = renewing_employees[2]
        create_person(ce, renewing_employer)
      }
  
      let!(:enrollment_6) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.active_benefit_group_assignment, employee_role: employee_C, submitted_at: effective_on.prev_year) 
      }

      let!(:enrollment_7) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.renewal_benefit_group_assignment, employee_role: employee_C, submitted_at: effective_on - 22.days, coverage_kind: 'dental')
      }

      let!(:enrollment_8) {
        create_enrollment(family: employee_C.person.primary_family, benefit_group_assignment: employee_C.census_employee.renewal_benefit_group_assignment, employee_role: employee_C, submitted_at: effective_on - 22.days, status: 'inactive') 
      }


      let(:employee_D) {
        ce = renewing_employees[2]
        create_person(ce, renewing_employer)
      }

      let!(:enrollment_9) {
        create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.active_benefit_group_assignment, employee_role: employee_D, submitted_at: effective_on.prev_year) 
      }

      let!(:enrollment_10) {
        create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.renewal_benefit_group_assignment, employee_role: employee_D, submitted_at: effective_on - 24.days, coverage_kind: 'dental')
      }

      let!(:enrollment_11) {
        create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.renewal_benefit_group_assignment, employee_role: employee_D, submitted_at: effective_on - 23.days, status: 'inactive') 
      }

      let!(:enrollment_12) {
        create_enrollment(family: employee_D.person.primary_family, benefit_group_assignment: employee_D.census_employee.renewal_benefit_group_assignment, employee_role: employee_D, submitted_at: effective_on - 22.days) 
      }

      let(:feins) {
        [renewing_employer.fein]
      }
      skip "shop monthly queries updated here in new model app/models/queries/named_enrollment_queries.rb need to move." do
        # it "includes enrollment 3" do
        #   result = Queries::NamedPolicyQueries.shop_monthly_terminations(feins, effective_on)
        #   expect(result).to include(enrollment_3.hbx_id)
        # end
        #
        # it "includes enrollment 6" do
        #   result = Queries::NamedPolicyQueries.shop_monthly_terminations(feins, effective_on)
        #   expect(result).to include(enrollment_6.hbx_id)
        # end
        #
        # it "does not include enrollment 1" do
        #   result = Queries::NamedPolicyQueries.shop_monthly_terminations(feins, effective_on)
        #   expect(result).not_to include(enrollment_1.hbx_id)
        # end
        #
        # it "does not include enrollment 9" do
        #   result = Queries::NamedPolicyQueries.shop_monthly_terminations(feins, effective_on)
        #   expect(result).not_to include(enrollment_9.hbx_id)
        # end
      end
    end
  end

  def create_person(ce, employer_profile)
    person = FactoryBot.create(:person, last_name: ce.last_name, first_name: ce.first_name)
    employee_role = FactoryBot.create(:employee_role, person: person, census_employee: ce, employer_profile: employer_profile)
    ce.update_attributes({employee_role: employee_role})
    Family.find_or_build_from_employee_role(employee_role)
    employee_role
  end

  def create_enrollment(family: nil, benefit_group_assignment: nil, employee_role: nil, status: 'coverage_selected', submitted_at: nil, enrollment_kind: 'open_enrollment', effective_date: nil, coverage_kind: 'health')
    benefit_group = benefit_group_assignment.benefit_group
    FactoryBot.create(:hbx_enrollment,:with_enrollment_members,
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
  end
end
