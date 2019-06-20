require File.join(Rails.root, "lib/mongoid_migration_task")

class RemoveEnrolledContingentState < MongoidMigrationTask
  def manage_enrollment(enrollment)
    enrollment.assign_attributes(aasm_state: "coverage_selected", is_any_enrollment_member_outstanding: true)
    enrollment.workflow_state_transitions << WorkflowStateTransition.new(from_state: "enrolled_contingent",
      to_state: "coverage_selected", comment: "Got rid of enrolled_contingent state via migration")
    enrollment.save!
  end

  def migrate
    start_of_year = TimeKeeper.date_of_record.beginning_of_year
    end_of_year = TimeKeeper.date_of_record.end_of_year
    Family.by_enrollment_effective_date_range(start_of_year, end_of_year).where(:"households.hbx_enrollments.aasm_state" => "enrolled_contingent").each do |family|
      begin
        contingent_enrollments = family.active_household.hbx_enrollments.current_year.where(aasm_state: "enrolled_contingent")
        if contingent_enrollments.present?
          contingent_enrollments.each { |enrollment| manage_enrollment(enrollment) }
          puts "Successfully migrated enrollments for family with family_id: #{family.id}" unless Rails.env.test?
        end
      rescue => e
        puts "Could not migrate enrollments for family with family_id: #{family.id}, Error: #{e.backtrace}" unless Rails.env.test?
      end
    end
  end
end
