def format_date(date)
  return 'not available' if date.blank?
  date.strftime("%m/%d/%Y")
end

orgs = Organization.where({
  :"employer_profile.profile_source" => 'conversion',
  :"employer_profile.plan_years" => { 
  :$elemMatch => { 
    :start_on => TimeKeeper.date_of_record.next_month.beginning_of_month, 
    :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE }
    }})


CSV.open("#{Rails.root}/EE_Enrollment_Cancellation_Report.csv", "w", force_quotes: true) do |csv|

csv << ['EE First Name', 'EE Last Name', 'EE SSN', 'EE DOB', 'ER Legal name', 'ER FEIN', 'EE Terminated On', 'Employment Termination Date', 'Plan Name', 'Plan HIOS', 'Effective Date', 'Submitted At', 'Current Status',  'Updated Status']
count = 0
orgs.each do |org|

  renewal_plan_year = org.employer_profile.plan_years.renewing.first
  id_list = renewal_plan_year.benefit_groups.collect(&:_id).uniq

  families = Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list)
  enrollments = families.inject([]) do |enrollments, family|
    policies = family.active_household.hbx_enrollments.where(:benefit_group_id.in => id_list).where({ 
      :aasm_state.in => (HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES),
      :coverage_kind => 'health'
    }).to_a
    
    # coverage = policies.detect{|x| x.aasm_state == 'coverage_selected'}

    # if coverage.blank?
    #   coverage = policies.detect{|x| x.aasm_state == 'auto_renewing'}
    # end
    
    enrollments += policies
  end

  people = []

  enrollments.compact.each do |enrollment|
    if enrollment.benefit_group_assignment.blank?
      puts "-------------------------------------------#{enrollment.subscriber.person.full_name} benefit group assignment missing"
      next
    end

    census_employee = enrollment.benefit_group_assignment.census_employee

    if !census_employee.is_active? && census_employee.employment_terminated_on < Date.new(2016, 7, 1)
      ee_row = [census_employee.first_name, census_employee.last_name, census_employee.ssn, format_date(census_employee.dob), census_employee.employer_profile.legal_name, census_employee.employer_profile.fein]

      transition = census_employee.workflow_state_transitions.where(:to_state => 'employment_terminated').first
      str = "#{enrollment.subscriber.person.full_name} -- #{enrollment.aasm_state} -- #{enrollment.submitted_at || enrollment.created_at}"
      
      if transition
        transition_at = transition.transition_at
        str += "---terminated on #{transition.transition_at}--actual termination date--#{census_employee.employment_terminated_on}"
      end

      ee_row << [format_date(transition_at), format_date(census_employee.employment_terminated_on), enrollment.plan.name, enrollment.plan.hios_id, format_date(enrollment.effective_on), format_date(enrollment.submitted_at || enrollment.created_at), enrollment.aasm_state]
      people << str
      enrollment.cancel_coverage!
      enrollment.reload
      ee_row << [enrollment.aasm_state]
      csv << ee_row.flatten
    end
  end

  if people.any?
    puts "----#{org.legal_name}"
    puts people
    puts "----------------------"
    count += 1
  end
end
puts count
end

