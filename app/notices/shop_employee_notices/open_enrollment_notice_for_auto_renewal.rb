class ShopEmployeeNotices::OpenEnrollmentNoticeForAutoRenewal < ShopEmployeeNotice
include ActionView::Helpers::NumberHelper

  attr_accessor :census_employee

  def deliver
    build
    append_data
    generate_pdf_notice
    non_discrimination_attachment
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def append_data
    renewing_plan_year = census_employee.employer_profile.plan_years.where(:aasm_state.in => PlanYear::RENEWING).first
    notice.plan_year = PdfTemplates::PlanYear.new({
      :start_on => renewing_plan_year.start_on,
      :open_enrollment_end_on => renewing_plan_year.open_enrollment_end_on
      })
    enrollment = census_employee.renewal_benefit_group_assignment.hbx_enrollments.first
    notice.plan = PdfTemplates::Plan.new({
      :plan_name => enrollment.plan.name
      })
    
    total_employee_cost =  number_to_currency(enrollment.total_employee_cost)
    notice.enrollment = PdfTemplates::Enrollment.new({
      :enrollees => enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
        enrollee = PdfTemplates::Individual.new({
          full_name: member.person.full_name.titleize })
        enrollees << enrollee end,
      :employee_cost => total_employee_cost
    })
  end

end