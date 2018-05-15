module BenefitSponsors
  class BenefitApplications::BenefitApplicationService

    def initialize(benefit_application)
      @benefit_application = benefit_application
    end


    # Check plan year for violations of model integrity relative to publishing
    def application_errors
      errors = {}

      if open_enrollment_end_on > (open_enrollment_start_on + (Settings.aca.shop_market.open_enrollment.maximum_length.months).months)
        log_message(errors){{open_enrollment_period: "Open Enrollment period is longer than maximum (#{Settings.aca.shop_market.open_enrollment.maximum_length.months} months)"}}
      end

      # if benefit_packages.any?{|bg| bg.reference_plan_id.blank? }
      #   log_message(errors){{benefit_packages: "Reference plans have not been selected for benefit packages. Please edit the benefit application and select reference plans."}}
      # end

      if benefit_packages.blank?
        log_message(errors) {{benefit_packages: "You must create at least one benefit package to publish a plan year"}}
      end

      # if benefit_sponsorship.census_employees.active.to_set != assigned_census_employees.to_set
      #   log_message(errors) {{benefit_packages: "Every employee must be assigned to a benefit package defined for the published plan year"}}
      # end

      if benefit_sponsorship.ineligible?
        log_message(errors) {{benefit_sponsorship:  "This employer is ineligible to enroll for coverage at this time"}}
      end

      if overlapping_published_plan_year?
        log_message(errors) {{ publish: "You may only have one published benefit application at a time" }}
      end

      if !is_publish_date_valid?
        log_message(errors) {{publish: "Plan year starting on #{start_on.strftime("%m-%d-%Y")} must be published by #{due_date_for_publish.strftime("%m-%d-%Y")}"}}
      end

      errors
    end

    # Check plan year application for regulatory compliance
    def application_eligibility_warnings
      warnings = {}
      unless benefit_sponsorship.profile.is_primary_office_local?
        warnings.merge!({primary_office_location: "Has its principal business address in the #{Settings.aca.state_name} and offers coverage to all full time employees through #{Settings.site.short_name} or Offers coverage through #{Settings.site.short_name} to all full time employees whose Primary worksite is located in the #{Settings.aca.state_name}"})
      end

      # Application is in ineligible state from prior enrollment activity
      if aasm_state == "application_ineligible" || aasm_state == "renewing_application_ineligible"
        warnings.merge!({ineligible: "Application did not meet eligibility requirements for enrollment"})
      end

      # Maximum company size at time of initial registration on the HBX
      if !(is_renewing?) && (fte_count > Settings.aca.shop_market.small_market_employee_count_maximum)
        warnings.merge!({ fte_count: "Has #{Settings.aca.shop_market.small_market_employee_count_maximum} or fewer full time equivalent employees" })
      end

      # Exclude Jan 1 effective date from certain checks
      unless effective_date.yday == 1
        # Employer contribution toward employee premium must meet minimum
        # TODO: FIX this once minimum_employer_contribution is fixed
        # if benefit_packages.size > 0 && (minimum_employer_contribution < Settings.aca.shop_market.employer_contribution_percent_minimum)
          # warnings.merge!({ minimum_employer_contribution:  "Employer contribution percent toward employee premium (#{minimum_employer_contribution.to_i}%) is less than minimum allowed (#{Settings.aca.shop_market.employer_contribution_percent_minimum.to_i}%)" })
        # end
      end

      warnings
    end

    # TODO review this
    def validate_application_dates
      return if canceled? || expired? || renewing_canceled?
      return if effective_period.blank? || open_enrollment_period.blank?
      # return if imported_plan_year

      if effective_period.begin.mday != effective_period.begin.beginning_of_month.mday
        errors.add(:effective_period, "start date must be first day of the month")
      end

      if effective_period.end.mday != effective_period.end.end_of_month.mday
        errors.add(:effective_period, "must be last day of the month")
      end

      if effective_period.end > effective_period.begin.years_since(Settings.aca.shop_market.benefit_period.length_maximum.year)
        errors.add(:effective_period, "benefit period may not exceed #{Settings.aca.shop_market.benefit_period.length_maximum.year} year")
      end

      if open_enrollment_period.end > effective_period.begin
        errors.add(:effective_period, "start date can't occur before open enrollment end date")
      end

      if open_enrollment_period.end < open_enrollment_period.begin
        errors.add(:open_enrollment_period, "can't occur before open enrollment start date")
      end

      if open_enrollment_period.begin < (effective_period.begin - Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "can't occur earlier than 60 days before start date")
      end

      if open_enrollment_period.end > (open_enrollment_period.begin + Settings.aca.shop_market.open_enrollment.maximum_length.months.months)
        errors.add(:open_enrollment_period, "open enrollment period is greater than maximum: #{Settings.aca.shop_market.open_enrollment.maximum_length.months} months")
      end

      ## Leave this validation disabled in the BQT??
      # if (effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months) > TimeKeeper.date_of_record
      #   errors.add(:effective_period, "may not start application before " \
      #              "#{(effective_period.begin + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months).to_date} with #{effective_period.begin} effective date")
      # end

      if !['canceled', 'suspended', 'terminated'].include?(aasm_state)
        #groups terminated for non-payment get 31 more days of coverage from their paid through date
        if end_on != end_on.end_of_month
          errors.add(:end_on, "must be last day of the month")
        end

        if end_on != (start_on + Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)
          errors.add(:end_on, "plan year period should be: #{duration_in_days(Settings.aca.shop_market.benefit_period.length_minimum.year.years - 1.day)} days")
        end
      end
    end



  end
end
