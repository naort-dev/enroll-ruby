def format_date(date)
  return 'not available' if date.blank?
  date.strftime("%m/%d/%Y")
end

orgs = Organization.where({ :"employer_profile.plan_years" => { 
  :$elemMatch => { 
    :start_on => TimeKeeper.date_of_record.next_month.beginning_of_month, 
    :aasm_state.in => PlanYear::RENEWING_PUBLISHED_STATE }
  }})

def to_csv(enrollment, census_employee)
  row = [
    census_employee.first_name, 
    census_employee.last_name, 
    census_employee.ssn, 
    format_date(census_employee.dob),
    census_employee.employer_profile.legal_name, 
    census_employee.employer_profile.fein
  ]

  row << [format_date(nil), format_date(census_employee.employment_terminated_on), enrollment.plan.try(:name), enrollment.plan.try(:hios_id), format_date(enrollment.effective_on), format_date(enrollment.submitted_at || enrollment.created_at), enrollment.aasm_state]
  return row
end

count = 0
counter = 0
CSV.open("#{Rails.root}/EEs_Renewed_without_active_coverage.csv", "w", force_quotes: true) do |csv|

  csv << ['EE First Name', 'EE Last Name', 'EE SSN', 'EE DOB', 'ER Legal name', 'ER FEIN', 'EE Terminated On', 'Employment Termination Date', 'Plan Name', 'Plan HIOS', 'Effective Date', 'Submitted At', 'Current Status',  'Updated Status']

  orgs.each do |org|
    begin
      counter += 1

      renewal_plan_year = org.employer_profile.renewing_published_plan_year
      next if renewal_plan_year.blank?

      active_plan_year = org.employer_profile.active_plan_year
      if active_plan_year.blank?
        puts "EXCEPTION: active plan year missing!! #{org.legal_name} #{org.fein}"
        next
      end

      people = []

      active_id_list = active_plan_year.benefit_groups.collect(&:_id).uniq
      id_list = renewal_plan_year.benefit_groups.collect(&:_id).uniq

      Family.where(:"households.hbx_enrollments.benefit_group_id".in => id_list).each do |family|

        renewals = family.active_household.hbx_enrollments.where({ 
          :aasm_state.in => HbxEnrollment::RENEWAL_STATUSES,
          :coverage_kind => 'health',
          :benefit_group_id.in => id_list,
          :effective_on => TimeKeeper.date_of_record.next_month.beginning_of_month
          })

        enrolled = family.active_household.hbx_enrollments.where({ 
          :aasm_state.in => HbxEnrollment::ENROLLED_STATUSES,
          :coverage_kind => 'health',
          :benefit_group_id.in => active_id_list
          }).select{|e| e.terminated_on.blank? || e.terminated_on >= Date.new(2016,12,1)}

        if enrolled.blank? && renewals.present?
          renewals.each do |enrollment|
            if enrollment.benefit_group_assignment.blank?
              puts "------------------------#{enrollment.subscriber.try(:person).try(:full_name)} benefit group assignment missing"
              next
            end

            census_employee = enrollment.benefit_group_assignment.census_employee
            row = to_csv(enrollment, census_employee)
            enrollment.cancel_coverage!
            enrollment.reload
            row << [enrollment.aasm_state]
            csv << row.flatten
          end
        end
      end

      if counter % 100 == 0
        puts "processed --#{counter}"
      end
    rescue Exception => e
      puts "#{e.inspect}"
    end
  end
end

puts count
