module BrokerAgencies::ProfilesHelper
  def fein_display(broker_agency_profile)
    (broker_agency_profile.organization.is_fake_fein? && !current_user.has_broker_agency_staff_role?)|| (broker_agency_profile.organization.is_fake_fein? && current_user.has_hbx_staff_role?) || !broker_agency_profile.organization.is_fake_fein?
  end

  def get_commission_statements_for_year(statements, year)
    results = []
    statements.each do |statement|
      if statement.date.year == year.to_i
        results << statement
      end
    end
    results
  end

  def commission_statement_formatted_date(date)
    date.strftime("%m/%d/%Y")
  end

  def commission_statement_coverage_period(date)
    "#{date.prev_month.beginning_of_month.strftime('%b %Y')}" rescue nil
  end

  def can_show_destroy_for_brokers?(broker_staff_member, total_broker_staff_count, broker_agency_profile)
    # Destroy button cannot be shown for final broker staff role
    return false if total_broker_staff_count == 1
    # Destroy button will always be shown to broker staff member if no broker role is present OR
    # Destroy button cannot be shown for broker staff member with primary broker role equal to broker agency profile primary broker
    return false if broker_agency_profile.primary_broker_role == broker_staff_member.broker_role
    broker_staff_member.broker_role.blank? || broker_staff_member.broker_role != broker_agency_profile.primary_broker_role
    #show the delete button if the broker_staff_member has a broker role but they are the primary broker on a different agency
  end

  def can_show_destroy_for_ga?(ga_staff_member, total_ga_staff_count)
    # Destroy button cannot be shown for final ga staff role
    return false if total_ga_staff_count == 1
    # Destroy button will always be shown to ga staff member OR
    # Destroy button cannot be shown for ga primary staff role
    ga_staff_member.general_agency_primary_staff.blank?
  end

  def disable_edit_broker_agency?(user)
    return false if user.has_hbx_staff_role?
    person = user.person
    person.broker_role.present? ? false : true
  end

  def disable_edit_general_agency?(user)
    return false if user.has_hbx_staff_role?
    person = user.person
    person.general_agency_primary_staff.present? ? false : true
  end
end
