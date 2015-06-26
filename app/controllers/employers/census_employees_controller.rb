class Employers::CensusEmployeesController < ApplicationController
  before_action :find_employer
  before_action :find_census_employee, only: [:edit, :update, :show, :delink, :terminate, :rehire, :benefit_group, :assignment_benefit_group ]
  before_action :check_plan_year, only: [:new]

  def new
    @census_employee = build_census_employee
  end

  def create
    @census_employee = CensusEmployee.new
    @census_employee.attributes = census_employee_params
    if Person.where(ssn: census_employee_params["ssn"].gsub('-','')).present?
      flash[:error] = "The provided SSN belongs to another person."
      render action: "new"
    elsif benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(benefit_group_id))
      new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, @census_employee)
      @census_employee.benefit_group_assignments = new_benefit_group_assignment.to_a
      @census_employee.employer_profile = @employer_profile
      if @census_employee.save
        flash[:notice] = "Census Employee is successfully created."
        redirect_to employers_employer_profile_path(@employer_profile)
      else
        render action: "new"
      end
    else
      @census_employee.benefit_group_assignments.build if @census_employee.benefit_group_assignments.blank?
      flash[:error] = "Please select Benefit Group."
      render action: "new"
    end
  end

  def edit
    @census_employee.build_address unless @census_employee.address.present?
    @census_employee.benefit_group_assignments.build unless @census_employee.benefit_group_assignments.present?
  end

  def update
    if benefit_group_id.present?
      benefit_group = BenefitGroup.find(BSON::ObjectId.from_string(benefit_group_id))
      new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, @census_employee)
      if @census_employee.active_benefit_group_assignment.try(:benefit_group_id) != new_benefit_group_assignment.benefit_group_id
        @census_employee.add_benefit_group_assignment(new_benefit_group_assignment)
      end

      @census_employee.attributes = census_employee_params
      authorize! :update, @census_employee
      if @census_employee.save
        flash[:notice] = "Census Employee is successfully updated."
        redirect_to employers_employer_profile_path(@employer_profile)
      else
        render action: "edit"
      end
    else
      flash[:error] = "Please select Benefit Group."
      render action: "edit"
    end
  end

  def terminate
    termination_date = params["termination_date"]
    if termination_date.present?
      termination_date = DateTime.strptime(termination_date, '%m/%d/%Y').try(:to_date)
    else
      termination_date = ""
    end
    last_day_of_work = termination_date
    if termination_date.present?
      @census_employee.terminate_employment(last_day_of_work)
      @fa = @census_employee.save
    end
    respond_to do |format|
      format.js {
        if termination_date.present? and @fa
          flash[:notice] = "Successfully terminated Census Employee."
          render text: true
        else
          render text: false
        end
      }
      format.all {
        flash[:notice] = "Successfully terminated Census Employee."
        redirect_to employers_employer_profile_path(@employer_profile)
      }
    end
  end

  def rehire
    rehiring_date = params["rehiring_date"]
    if rehiring_date.present?
      rehiring_date = DateTime.strptime(rehiring_date, '%m/%d/%Y').try(:to_date)
    else
      rehiring_date = ""
    end
    @rehiring_date = rehiring_date
    if @rehiring_date.present? and @rehiring_date > @census_employee.employment_terminated_on
      new_census_employee = @census_employee.replicate_for_rehire
      if new_census_employee.present? # not an active family, then it is ready for rehire.#
        new_census_employee.hired_on = @rehiring_date
        new_census_employee.employer_profile = @employer_profile
        if new_census_employee.valid? and @census_employee.valid?
          new_census_employee.save
          @census_employee.save
          flash[:notice] = "Successfully rehired Census Employee."
        else
          flash[:error] = "Error during rehire."
        end
      else # active family, dont replicate for rehire, just return error
        flash[:error] = "Census Employee is already active."
      end
    elsif @rehiring_date.blank?
      flash[:error] = "Please enter rehiring date."
    else
      flash[:error] = "Rehiring date can't occur before terminated date."
    end
  end

  def show
  end

  def delink
    authorize! :delink, @census_employee
    @census_employee.delink_employee_role
    @census_employee.save!
    flash[:notice] = "Successfully delinked census employee."
    redirect_to employers_employer_profile_path(@employer_profile)
  end

  def benefit_group
    @census_employee.benefit_group_assignments.build unless @census_employee.benefit_group_assignments.present?
  end

  def assignment_benefit_group
    benefit_group = @employer_profile.plan_years.first.benefit_groups.find_by(id: benefit_group_id)
    new_benefit_group_assignment = BenefitGroupAssignment.new_from_group_and_census_employee(benefit_group, @census_employee)

    if @census_employee.active_benefit_group_assignment.try(:benefit_group_id) != new_benefit_group_assignment.benefit_group_id
      @census_employee.add_benefit_group_assignment(new_benefit_group_assignment)
    end

    if @census_employee.save
      flash[:notice] = "Assignment benefit group is successfully."
      redirect_to employers_employer_profile_path(@employer_profile)
    else
      render action: "benefit_group"
    end
  end

  private

  def benefit_group_id
    params[:census_employee][:benefit_group_assignments_attributes]["0"][:benefit_group_id]
  end

  def census_employee_params
=begin
    [:dob, :hired_on].each do |attr|
      if params[:census_employee][attr].present?
        params[:census_employee][attr] = DateTime.strptime(params[:census_employee][attr].to_s, '%m/%d/%Y').try(:to_date)
      end
    end

    census_dependents_attributes = params[:census_employee][:census_dependents_attributes]
    if census_dependents_attributes.present?
      census_dependents_attributes.each do |id, dependent_params|
        if census_dependents_attributes[id][:dob].present?
          params[:census_employee][:census_dependents_attributes][id][:dob] = DateTime.strptime(dependent_params[:dob].to_s, '%m/%d/%Y').try(:to_date)
        end
      end
    end
=end

    params.require(:census_employee).permit(:id, :employer_profile_id,
        :id, :first_name, :middle_name, :last_name, :name_sfx, :dob, :ssn, :gender, :hired_on, :employment_terminated_on, :is_business_owner,
        :address_attributes => [ :id, :kind, :address_1, :address_2, :city, :state, :zip ],
        :email_attributes => [:id, :kind, :address],
      :census_dependents_attributes => [
          :id, :first_name, :last_name, :middle_name, :name_sfx, :dob, :gender, :employee_relationship, :_destroy
        ]
      )
  end

  def find_employer
    @employer_profile = EmployerProfile.find(params["employer_profile_id"])
  end

  def find_census_employee
    id = params[:id] || params[:census_employee_id]
    @census_employee = CensusEmployee.find(id)
  end

  def build_census_employee
    @census_employee = CensusEmployee.new
    @census_employee.build_address
    @census_employee.build_email
    @census_employee.benefit_group_assignments.build
    @census_employee
  end

  def check_plan_year
    if @employer_profile.plan_years.empty?
      flash[:notice] = "Please create a plan year before you create your first census employee."
      redirect_to new_employers_employer_profile_plan_year_path(@employer_profile)
    end
  end

end
