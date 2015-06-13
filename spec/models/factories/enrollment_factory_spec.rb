require 'rails_helper'

describe Factories::EnrollmentFactory, "starting with unlinked employee_family and employee_role" do
  let(:hired_on) { Date.new(2015,1,15) }
  let(:terminated_on) { Date.new(2015,3,25) }

  let(:employer_profile) { EmployerProfile.new }
  let(:plan_year) {employer_profile.plan_years.build}
  let(:benefit_group) {plan_year.benefit_groups.build}
  let(:census_employee) { CensusEmployee.new({
      :hired_on => hired_on,
      :employment_terminated_on => terminated_on,
      :employer_profile => employer_profile,
      :aasm_state => "eligible"
    })
  }
  let(:benefit_group_assignment) {
    BenefitGroupAssignment.new({
      benefit_group_id: benefit_group.id,
      :start_on => Date.new(2015,1,1),
      is_active: true
    })
  }

  let(:employee_role) {
    EmployeeRole.new
  }

  describe "After performing the link" do

    before(:each) do
      census_employee.benefit_group_assignments = [benefit_group_assignment]
      Factories::EnrollmentFactory.link_census_employee(census_employee, employee_role, employer_profile)
    end

    it "should set employee role id on the census employee" do
      expect(census_employee.employee_role_id).to eq employee_role.id
    end

    it "should set employer profile id on the employee_role" do
      expect(employee_role.employer_profile_id).to eq employer_profile.id
    end

    it "should set census family id on the employee_role" do
      expect(employee_role.census_employee_id).to eq census_employee.id
    end

    it "should set hired on on the employee_role" do
      expect(employee_role.hired_on).to eq hired_on
    end

    it "should set terminated on on the employee_role" do
      expect(employee_role.terminated_on).to eq terminated_on
    end
  end
end

RSpec.describe Factories::EnrollmentFactory, :dbclean => :after_each do
  let(:employer_profile_without_family) {FactoryGirl.create(:employer_profile)}
  let(:employer_profile) {FactoryGirl.create(:employer_profile)}
  let(:plan_year) {FactoryGirl.create(:plan_year, employer_profile: employer_profile)}
  let(:benefit_group) {FactoryGirl.create(:benefit_group, plan_year: plan_year)}
  let(:benefit_group_assignment) {FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group, :start_on => plan_year.start_on, is_active: true)}
  let(:census_employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id, benefit_group_assignments: [benefit_group_assignment])}
  let(:user) {FactoryGirl.create(:user)}
  let(:first_name) {census_employee.first_name}
  let(:last_name) {census_employee.last_name}
  let(:ssn) {census_employee.ssn}
  let(:dob) {census_employee.dob}
  let(:gender) {census_employee.gender}
  let(:hired_on) {census_employee.hired_on}

  let(:valid_person_params) do
    {
      user: user,
      first_name: first_name,
      last_name: last_name,
    }
  end
  let(:valid_employee_params) do
    {
      ssn: ssn,
      gender: gender,
      dob: dob,
      hired_on: hired_on
    }
  end
  let(:valid_params) do
    {employer_profile: employer_profile}.merge(valid_person_params).merge(valid_employee_params)
  end

  context "an employer profile exists with an employee and depenedents in the census" do
    let(:census_dependent){FactoryGirl.build(:census_dependent)}
    let(:primary_applicant) {@family.primary_applicant}
    let(:params) {valid_params}

    def before
      census_employee.census_dependents = [census_dependent]
      census_employee.save
    end

    context "and no prior person exists" do
      before do
        @user = FactoryGirl.create(:user)
        # employer_profile = FactoryGirl.create(:employer_profile)
        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        valid_employee_params = {
          ssn: census_employee.ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(
          valid_person_params
        ).merge(valid_employee_params)
        params = valid_params
        @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)
        @primary_applicant = @family.primary_applicant
      end

      it "should have a family" do
        expect(@family).to be_a Family
      end

      it "should be the primary applicant" do
        expect(@employee_role.person).to eq @primary_applicant.person
      end

      it "should have linked the family" do
        expect(CensusEmployee.find(census_employee.id).employee_role).to eq @employee_role
      end

      it "should have all family_members" do
        expect(@family.family_members.count).to eq (census_employee.census_dependents.count + 1)
      end

      it "should set a home email" do
        email = @employee_role.person.emails.first
        expect(email.address).to eq @user.email
        expect(email.kind).to eq "home"
      end
    end

    context "and a prior person exists but is not associated with the user" do

      before do
        @user = FactoryGirl.create(:user)
        census_dependent = FactoryGirl.build(:census_dependent)
        benefit_group_assignment = FactoryGirl.build(:benefit_group_assignment)
        census_employee = FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
          census_dependents: [census_dependent],
          benefit_group_assignments: [benefit_group_assignment])
        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        valid_employee_params = {
          ssn: census_employee.ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(valid_person_params).merge(valid_employee_params)
        params = valid_params
        @person = FactoryGirl.create(:person,
                                     valid_person_params.except(:user).merge(dob: census_employee.dob,
                                                                             ssn: census_employee.ssn))
        @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)
      end

      it "should link the user to the person" do
        expect(@employee_role.person.user).to eq @user
      end

      it "should link the person to the user" do
        expect(@user.person).to eq @person
      end

      it "should add the employee role to the user" do
        expect(@user.roles).to include "employee"
      end
    end

    context "and another employer profile exists with the same employee and dependents in the census"  do
      before do
        @user = FactoryGirl.create(:user)
        employer_profile = FactoryGirl.create(:employer_profile)
        plan_year = FactoryGirl.create(:plan_year, employer_profile: employer_profile)
        benefit_group = FactoryGirl.create(:benefit_group, plan_year: plan_year)
        census_dependent = FactoryGirl.build(:census_dependent)
        benefit_group_assignment = FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group, :start_on => plan_year.start_on, is_active: true)
        census_employee = FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
                                              census_dependents: [census_dependent],
                                              benefit_group_assignments: [benefit_group_assignment])
        valid_person_params = {
          user: @user,
          first_name: census_employee.first_name,
          last_name: census_employee.last_name,
        }
        @ssn = census_employee.ssn
        valid_employee_params = {
          ssn: @ssn,
          gender: census_employee.gender,
          dob: census_employee.dob,
          hired_on: census_employee.hired_on
        }
        valid_params = { employer_profile: employer_profile }.merge(valid_person_params).merge(valid_employee_params)
        @first_employee_role, @first_family = Factories::EnrollmentFactory.add_employee_role(**valid_params)

        dependents = census_employee.census_dependents.collect(&:dup)
        employee = census_employee.dup


        employer_profile_2 = FactoryGirl.create(:employer_profile)
        plan_year_2 = FactoryGirl.create(:plan_year, employer_profile: employer_profile_2)
        benefit_group_2 = FactoryGirl.create(:benefit_group, plan_year: plan_year_2)
        census_dependent_2 = census_dependent.dup
        benefit_group_assignment_2 = FactoryGirl.build(:benefit_group_assignment, benefit_group: benefit_group_2, :start_on => plan_year_2.start_on, is_active: true)
        census_employee_2 = census_employee.dup
        census_employee_2.employer_profile_id = employer_profile_2.id
        census_employee_2.census_dependents = [census_dependent_2]
        census_employee_2.benefit_group_assignments = [benefit_group_assignment_2]
        census_employee_2.save


        @second_params = { employer_profile: employer_profile_2 }.merge(valid_person_params).merge(valid_employee_params)
        @second_employee_role, @second_census_employee = Factories::EnrollmentFactory.add_employee_role(**@second_params)
      end

      it "should still have a findable person" do
        people = Person.match_by_id_info(ssn: @ssn)
        expect(people.count).to eq 1
        expect(people.first).to be_a Person
      end

      it "second employee role should be saved" do
        expect(@second_employee_role.persisted?).to be
      end

      it "second family should be saved" do
        expect(@second_census_employee.persisted?).to be
      end

      it "second employee role should be valid" do
        expect(@second_employee_role.valid?).to be
      end

      it "second family should be the first family" do
        expect(@second_census_employee).to eq @first_family
      end
    end
  end

  describe ".add_employee_role" do
    context "when the employee already exists but is not linked" do
      let(:census_dependent){FactoryGirl.build(:census_dependent)}
      let(:benefit_group_assignment){FactoryGirl.build(:benefit_group_assignment)}
      let(:census_employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
        census_dependents: [census_dependent],
        benefit_group_assignments: [benefit_group_assignment])}
      let(:existing_person) {FactoryGirl.create(:person, valid_person_params)}
      let(:employee) {FactoryGirl.create(:employee_role, valid_employee_params.merge(person: existing_person, employer_profile: employer_profile))}
      before {user;census_employee;employee}

      context "with all required data" do
        let(:params) {valid_params}

        it "should not raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
        end

        context "successfully created" do
          let(:primary_applicant) {family.primary_applicant}
          let(:employer_census_families) do
            EmployerProfile.find(employer_profile.id.to_s).employee_families
          end
          before {@employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)}

          it "should return the existing employee" do
            expect(@employee_role.id.to_s).to eq employee.id.to_s
          end

          it "should return a family" do
            expect(@family).to be_a Family
          end
        end
      end
    end

    context "census_employee params" do
      let(:benefit_group_assignment){FactoryGirl.build(:benefit_group_assignment)}
      let(:census_dependent){FactoryGirl.build(:census_dependent)}
      let(:census_employee) {FactoryGirl.create(:census_employee, employer_profile_id: employer_profile.id,
              census_dependents: [census_dependent],
              benefit_group_assignments: [benefit_group_assignment])}
      context "with no arguments" do
        let(:params) {{}}

        it "should raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no user' do
        let(:params) {valid_params.except(:user)}

        it 'should not raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
        end
      end

      context 'with no employer_profile' do
        let(:params) {valid_params.except(:employer_profile)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no first_name' do
        let(:params) {valid_params.except(:first_name)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no last_name' do
        let(:params) {valid_params.except(:last_name)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no ssn' do
        let(:params) {valid_params.except(:ssn)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no gender' do
        let(:params) {valid_params.except(:gender)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no dob' do
        let(:params) {valid_params.except(:dob)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context 'with no hired_on' do
        let(:params) {valid_params.except(:hired_on)}

        it 'should raise' do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context "with all required data, but employer_profile has no families" do
        let(:params) {valid_params.merge(employer_profile: employer_profile_without_family)}

        it "should raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.to raise_error(ArgumentError)
        end
      end

      context "with all required data" do
        let(:params) {valid_params}

        it "should not raise" do
          expect{Factories::EnrollmentFactory.add_employee_role(**params)}.not_to raise_error
        end

        context "successfully created" do
          let(:primary_applicant) {@family.primary_applicant}

          before do
            @employee_role, @family = Factories::EnrollmentFactory.add_employee_role(**params)
          end

          it "should have a family" do
            expect(@family).to be_a Family
          end

          it "should be the primary applicant" do
            expect(@employee_role.person).to eq primary_applicant.person
          end

          it "should have linked the family" do
            expect(CensusEmployee.find(census_employee.id).employee_role).to eq @employee_role
          end
        end
      end
    end
  end

  describe ".add_consumer_role" do
    let(:is_incarcerated) {true}
    let(:is_applicant) {true}
    let(:is_state_resident) {true}
    let(:citizen_status) {"us_citizen"}
    let(:valid_person) {FactoryGirl.create(:person)}

    let(:valid_params) do
      { person: valid_person,
        new_is_incarcerated: is_incarcerated,
        new_is_applicant: is_applicant,
        new_is_state_resident: is_state_resident,
        new_ssn: ssn,
        new_dob: dob,
        new_gender: gender,
        new_citizen_status: citizen_status
      }
    end

    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no is_incarcerated" do
      let(:params) {valid_params.except(:new_is_incarcerated)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no is_applicant" do
      let(:params) {valid_params.except(:new_is_applicant)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no is_state_resident" do
      let(:params) {valid_params.except(:new_is_state_resident)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no citizen_status" do
      let(:params) {valid_params.except(:new_citizen_status)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{Factories::EnrollmentFactory.add_consumer_role(**params)}.not_to raise_error
      end
    end

  end


  describe ".add_broker_role" do
    let(:mailing_address) do
      {
        kind: 'home',
        address_1: 1111,
        address_2: 111,
        city: 'Washington',
        state: 'DC',
        zip: 11111
      }
    end

    let(:npn) {"xyz123xyz"}
    let(:broker_kind) {"broker"}
    let(:valid_params) do
      { person: valid_person,
        new_npn: npn,
        new_kind: broker_kind,
        new_mailing_address: mailing_address
      }
    end
    let(:valid_person) {FactoryGirl.create(:person)}

    context "with no arguments" do
      let(:params) {{}}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with all required data" do
      let(:params) {valid_params}
      it "should not raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.not_to raise_error
      end
    end

    context "with no npn" do
      let(:params) {valid_params.except(:new_npn)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no kind" do
      let(:params) {valid_params.except(:new_kind)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

    context "with no mailing address" do
      let(:params) {valid_params.except(:new_mailing_address)}
      it "should raise" do
        expect{Factories::EnrollmentFactory.add_broker_role(**params)}.to raise_error(ArgumentError)
      end
    end

  end
end
