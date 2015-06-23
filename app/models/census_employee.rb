class CensusEmployee < CensusMember
  include AASM
  include Sortable

  field :is_business_owner, type: Boolean, default: false
  field :hired_on, type: Date
  field :employment_terminated_on, type: Date
  field :aasm_state, type: String

  # Employer for this employee
  field :employer_profile_id, type: BSON::ObjectId

  # Employee linked to this roster record
  field :employee_role_id, type: BSON::ObjectId

  embeds_many :census_dependents,
    cascade_callbacks: true,
    validate: true

  embeds_many :benefit_group_assignments,
    cascade_callbacks: true,
    validate: true

  accepts_nested_attributes_for :census_dependents, :benefit_group_assignments

  validates_presence_of :employer_profile_id, :ssn, :dob, :hired_on, :is_business_owner
  validate :check_employment_terminated_on

  index({"aasm_state" => 1})
  index({"employer_profile_id" => 1}, {sparse: true})
  index({"employee_role_id" => 1}, {sparse: true})
  index({"last_name" => 1})
  index({"hired_on" => -1})
  index({"is_business_owner" => 1})
  index({"ssn" => 1})
  index({"dob" => 1})
  index({"ssn" => 1, "dob" => 1, "aasm_state" => 1})
  index({"benefit_group_assignments._id" => 1})
  index({"benefit_group_assignments.benefit_group_id" => 1})
  index({"benefit_group_assignments.aasm_state" => 1})

  scope :active,      ->{ any_in(aasm_state: ["eligible", "employee_role_linked"]) }
  scope :terminated,  ->{ any_in(aasm_state: ["employment_terminated", "rehired"]) }

  #TODO - need to add fix for multiple plan years
  scope :enrolled,    ->{ any_in("benefit_group_assignments.aasm_state" => ["coverage_selected", "coverage_waived"]) }
  scope :waived,      ->{ where( "benefit_group_assignments.aasm_state" => "coverage_waived" ) }

  scope :sorted,                -> { order(:"census_employee.last_name".asc, :"census_employee.first_name".asc)}
  scope :order_by_last_name,    -> { order(:"census_employee.last_name".asc) }
  scope :order_by_first_name,   -> { order(:"census_employee.first_name".asc) }

  scope :non_business_owner,    ->{ where(is_business_owner: false) }
  scope :by_benefit_group_ids,  ->(benefit_group_ids) { any_in("benefit_group_assignments.benefit_group_id" => benefit_group_ids) }

  def initialize(*args)
    super(*args)
    write_attribute(:employee_relationship, "self")
  end

  def employer_profile=(new_employer_profile)
    raise ArgumentError.new("expected EmployerProfile") unless new_employer_profile.is_a?(EmployerProfile)
    self.employer_profile_id = new_employer_profile._id
    @employer_profile = new_employer_profile
  end

  def employer_profile
    return @employer_profile if defined? @employer_profile
    @employer_profile = EmployerProfile.find(self.employer_profile_id) unless self.employer_profile_id.blank?
  end

  def employee_role=(new_employee_role)
    raise ArgumentError.new("expected EmployeeRole") unless new_employee_role.is_a? EmployeeRole
    return false unless self.may_link_employee_role?

    # Guard against linking employee roles with different employer/identifying information
    if (self.ssn == new_employee_role.ssn) && (self.dob == new_employee_role.dob) &&
       (self.employer_profile_id == new_employee_role.employer_profile._id)

      self.employee_role_id = new_employee_role._id
      self.link_employee_role
      @employee_role = new_employee_role
    else
      message =  "Identifying information mismatch error linking employee role: "
      message << "#{new_employee_role.inspect} "
      message << "with census employee: #{self.inspect}"
      Rails.logger.error { message }
      raise CensusEmployeeError, message
    end
  end

  def employee_role
    return @employee_role if defined? @employee_role
    @employee_role = EmployeeRole.find(self.employee_role_id) unless self.employee_role_id.blank?
  end

  def add_benefit_group_assignment(new_benefit_group, start_on = Date.current)
    raise ArgumentError, "expected BenefitGroup" unless new_benefit_group.is_a?(BenefitGroup)

    if active_benefit_group_assignment.present?
      active_benefit_group_assignment.end_on = [new_benefit_group.start_on - 1.day, active_benefit_group_assignment.start_on].max
      active_benefit_group_assignment.is_active = false
    end

    bga = BenefitGroupAssignment.new(benefit_group: new_benefit_group, start_on: start_on)
    benefit_group_assignments << bga
  end

  def active_benefit_group_assignment
    benefit_group_assignments.detect { |assignment| assignment.is_active? }
  end

  def inactive_benefit_group_assignments
    benefit_group_assignments.reject(&:is_active?)
  end

  # Initialize a new, refreshed instance for rehires via deep copy
  def replicate_for_rehire
    return nil unless self.employment_terminated?
    new_employee = self.dup
    new_employee.hired_on = nil
    new_employee.employment_terminated_on = nil
    new_employee.employee_role_id = nil
    new_employee.benefit_group_assignments = []
    new_employee.aasm_state = :eligible
    self.rehire_employee_role

    # new_employee.census_dependents = self.census_dependents unless self.census_dependents.blank?
    new_employee
  end

  def is_business_owner?
    is_business_owner
  end

  def terminate_employment(terminated_on)
    begin
      terminate_employment!(terminated_on)
    rescue
      nil
    else
      self
    end
  end

  def terminate_employment!(terminated_on)
    unless self.may_terminate_employee_role?
      (employee_role.present? && employee_role.hbx_id.present?) ? ee_id = "(ee role id: #{self.employee_role.hbx_id})" : ee_id = "(census id: #{self.id})"
      active_benefit_group_assignment.present? ? bga_status = "#{active_benefit_group_assignment.aasm_state.tr('_', ' ')}. " : bga_status = "no benefit group assigned. "
      message =  "Unable to terminate employee.  Employment status: #{aasm_state.tr('_', ' ')}. "\
        "Coverage status: #{bga_status} #{ee_id}"
      Rails.logger.error { message }
      raise CensusEmployeeError, message
    end

    self.employment_terminated_on = terminated_on.to_date.end_of_day

    # Coverage termination date may not exceed HBX max
    reported_coverage_term_on = self.employment_terminated_on.end_of_month
    max_coverage_term_on = (Date.current.end_of_day - HbxProfile::ShopRetroactiveTerminationMaximum).end_of_month
    coverage_term_on = [reported_coverage_term_on, max_coverage_term_on].compact.max

    active_benefit_group_assignment.terminate_coverage(coverage_term_on) if active_benefit_group_assignment.try(:may_terminate_coverage?)
    terminate_employee_role
    self
  end

  def check_employment_terminated_on
    if employment_terminated_on and employment_terminated_on <= hired_on
      errors.add(:employment_terminated_on, "can't occur before rehiring date")
    end
  end

  def publish_plan_year(published_benefit_group)
    employee_role.benefit_group = published_benefit_group
    employee_role.save
  end

  class << self
    def find_all_unlinked_by_identifying_information(ssn, dob)
      unscoped.and(ssn: ssn, dob: dob, aasm_state: "eligible").to_a
    end

    def find_all_by_employer_profile(employer_profile)
      unscoped.where(employer_profile_id: employer_profile._id).order_name_asc
    end

    alias_method :find_by_employer_profile, :find_all_by_employer_profile

    def find_all_by_employee_role(employee_role)
      unscoped.where(employee_role_id: employee_role._id)
    end

    def find_all_by_benefit_group(benefit_group)
      unscoped.where("benefit_group_assignments.benefit_group_id" => benefit_group._id)
    end
  end

  aasm do
    state :eligible, initial: true
    state :employee_role_linked
    state :employment_terminated
    state :rehired

    event :rehire_employee_role do
      transitions from: [:employment_terminated], to: :rehired
    end

    event :link_employee_role do
      transitions from: :eligible, to: :employee_role_linked,
        :guard => :has_active_benefit_group_assignment?
    end

    event :delink_employee_role do
      transitions from: :employee_role_linked, to: :eligible,
        :after => :clear_employee_role
    end

    event :terminate_employee_role do
      transitions from: [:eligible, :employee_role_linked], to: :employment_terminated
    end
  end

private
  def may_terminate_benefit_group_assignment_coverage?
    if active_benefit_group_assignment.present? && active_benefit_group_assignment.may_terminate_coverage?
      return true
    else
      return false
    end
  end

  def has_active_benefit_group_assignment?
    active_benefit_group_assignment.present?
  end

  def clear_employee_role
    self.employee_role_id = nil
    unset("employee_role_id")
    @employee_role = nil
  end
end

class CensusEmployeeError < StandardError; end
