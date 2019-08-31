class CensusEmployeePolicy < ApplicationPolicy
  # TODO: JF JULY 1 review this
  # Last updated July 23 from https://github.com/dchbx/enroll/pull/2782/
  def update?
    return true if @user.has_role?(:hbx_staff)
    can_change =
      if @user.has_role?(:employer_staff) && !@user.has_role?(:broker)
        @user.person.employer_staff_roles.map(&:benefit_sponsor_employer_profile_id).map(&:to_s).include? @record.benefit_sponsors_employer_profile_id.to_s
      elsif @user.has_role?(:broker)
        @record.employer_profile.try(:active_broker) == @user.person
      elsif @user.has_role?(:general_agency_staff)
        ga_account = @record.employer_profile.general_agency_accounts.select do |general_agency_account|
          @user.person.general_agency_staff_roles.where(benefit_sponsors_general_agency_profile_id: general_agency_account.benefit_sponsrship_general_agency_profile_id)
        end.first
        ga_account.present? && ga_account.active?
      else
        false
      end
    can_change || (!@record.dob_changed? && !@record.ssn_changed?)
  end

  def show?
    return true if @user.has_role?(:hbx_staff) || @user.has_hbx_staff_role?
    return true if (@user.has_role?(:broker) || @user.has_broker_role?) && @record.employer_profile.try(:active_broker) == @user.person
    return true if (@user.has_role?(:employer_staff) || @user.has_employer_staff_role?) && @user.person.employer_staff_roles.map(&:benefit_sponsor_employer_profile_id).map(&:to_s).include?(@record.benefit_sponsors_employer_profile_id.to_s)
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