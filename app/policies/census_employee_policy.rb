class CensusEmployeePolicy < ApplicationPolicy
  # TODO: JF JULY 1 review this
  # Last updated July 23 from https://github.com/dchbx/enroll/pull/2782/
  def update?
    return true if @user.has_role?(:hbx_staff)
    if @user.has_role?(:employer_staff) && !@user.has_role?(:broker)
      can_change = @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include? @record.employer_profile_id.to_s
    elsif @user.has_role?(:broker)
      can_change = @record.employer_profile.try(:active_broker) == @user.person
    elsif @user.has_role?(:general_agency_staff)
      emp_ids = EmployerProfile.find_by_general_agency_profile(@user.person.general_agency_staff_roles.first.general_agency_profile).map(&:id)
      can_change = emp_ids.include?(@record.employer_profile.id)
    else
      can_change = false
    end
    can_change || (!@record.dob_changed? && !@record.ssn_changed?)
  end

  def show?
    return true if @user.has_role?(:hbx_staff) || @user.has_hbx_staff_role?
    return true if (@user.has_role?(:broker) || @user.has_broker_role?) && @record.employer_profile.try(:active_broker) == @user.person
    return true if (@user.has_role?(:employer_staff) || @user.has_employer_staff_role?) && @user.person.employer_staff_roles.map(&:employer_profile_id).map(&:to_s).include?(@record.employer_profile_id.to_s)
    return false if !@user.has_role?(:general_agency_staff) || !@user.has_general_agency_staff_role?
    ga_id = @user.person.general_agency_staff_roles.last.general_agency_profile.id
    employer_id = @record.employer_profile.id
    return false if ga_id.nil? || employer_id.nil?
    plan_design_organizations = SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_sponsor(employer_id)
    plan_design_organizations.each do |a|
      if a.general_agency_profile.present?
        return true if a.general_agency_profile.id == ga_id
      end
    end
  end

  def delink?
    %i[hbx_staff broker_agency_staff broker].any? { |role| @user.has_role?(role) } && @record.is_linked?
  end
end
