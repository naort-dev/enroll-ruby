module Notifier
  module Builders::HbxEnrollment

    def enrollment
      return @enrollment if defined? @enrollment
      if payload['event_object_kind'].constantize == HbxEnrollment
        @enrollment = HbxEnrollment.find(payload['event_object_id'])
      end
    end

    def enrollment_coverage_start_on
      return if enrollment.blank?
      merge_model.enrollment.coverage_start_on = format_date(enrollment.effective_on)
    end

    def enrollment_coverage_end_on
    	return if enrollment.blank?
      merge_model.enrollment.coverage_end_on = format_date(enrollment.terminated_on)
    end

    def enrollment_enrolled_count
    	return if enrollment.blank?
    	merge_model.enrollment.enrolled_count = enrollment.humanized_dependent_summary
    end

    def enrollment_employee_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employee_responsible_amount = number_to_currency(enrollment.total_employee_cost, precision: 2)
    end

    def enrollment_employer_responsible_amount
      return if enrollment.blank?
      merge_model.enrollment.employer_responsible_amount = number_to_currency(enrollment.total_employer_contribution, precision: 2)
    end

  end
end