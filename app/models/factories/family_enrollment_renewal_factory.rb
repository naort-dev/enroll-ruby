module Factories
  class FamilyEnrollmentRenewalFactory
    include Mongoid::Document

    # Renews a family's active enrollments from current plan year

    attr_accessor :family, :census_employee, :employer, :renewing_plan_year, :enrollment, :disable_notifications

    def initialize
      @disable_notifications = false
    end

    def renew

      if enrollment.present?
        set_instance_variables
      end

      raise ArgumentError unless defined?(family)

      ## Works only for data migrated into Enroll
      ## FIXME add logic to support Enroll native renewals


      shop_enrollments  = family.active_household.hbx_enrollments.enrolled.shop_market.by_coverage_kind('health').to_a
      shop_enrollments += family.active_household.hbx_enrollments.waived.to_a

      if shop_enrollments.any?{|enrollment| renewing_plan_year.benefit_groups.map(&:id).include?(enrollment.benefit_group_id) }
        return true
      end

      @plan_year_start_on  = renewing_plan_year.start_on
      prev_plan_year_start = @plan_year_start_on - 1.year
      prev_plan_year_end   = @plan_year_start_on - 1.day

      shop_enrollments.reject!{|enrollment| !(prev_plan_year_start..prev_plan_year_end).cover?(enrollment.effective_on) }
      shop_enrollments.reject!{|enrollment| enrollment.coverage_termination_pending? }
      begin
        if shop_enrollments.present?
          passive_renewals = family.active_household.hbx_enrollments.where(:aasm_state.in => HbxEnrollment::RENEWAL_STATUSES).to_a

          passive_renewals.reject! do |renewal|
            renewal.benefit_group.elected_plan_ids.include?(renewal.plan_id) ? false : (renewal.cancel_coverage!; true)
          end

          if passive_renewals.blank?
            active_enrollment = shop_enrollments.compact.sort_by{|e| e.submitted_at || e.created_at }.last
            if active_enrollment.present? && active_enrollment.inactive?
              renew_waived_enrollment(active_enrollment)
              ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, "employee_open_enrollment_unenrolled") unless disable_notifications
            elsif renewal_plan_offered_by_er?(active_enrollment)
              renewal_enrollment = renewal_builder(active_enrollment)
              renewal_enrollment = clone_shop_enrollment(active_enrollment, renewal_enrollment)
              renewal_enrollment.decorated_hbx_enrollment
              save_renewal_enrollment(renewal_enrollment, active_enrollment)
              ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, "employee_open_enrollment_auto_renewal") unless renewal_enrollment.coverage_kind == "dental" || disable_notifications
            else
              ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, "employee_open_enrollment_no_auto_renewal") unless disable_notifications
            end
          end
        elsif family.active_household.hbx_enrollments.where(:aasm_state => 'renewing_waived').blank?
          renew_waived_enrollment
          ShopNoticesNotifierJob.perform_later(census_employee.id.to_s, "employee_open_enrollment_unenrolled") unless disable_notifications
        end
      rescue Exception => e
        "Error found for #{census_employee.full_name} while creating renewals -- #{e.inspect}" unless Rails.env.test?
      end

      return family
    end

    def renewal_plan_offered_by_er?(enrollment)
      if enrollment.plan.present? || enrollment.plan.renewal_plan(renewing_plan_year.start_on).present?

        if @census_employee.renewal_benefit_group_assignment.blank?
          benefit_group = renewing_plan_year.default_benefit_group || renewing_plan_year.benefit_groups.first
          @census_employee.add_renew_benefit_group_assignment(benefit_group)
          @census_employee.save!
        end

        @census_employee.renewal_benefit_group_assignment.benefit_group.elected_plan_ids.include?(enrollment.plan.renewal_plan(renewing_plan_year.start_on).id)
      else
        false
      end
    end

    def renew_waived_enrollment(waived_enrollment = nil)
      renewal_enrollment = family.active_household.hbx_enrollments.new

      renewal_enrollment.coverage_kind = "health"
      renewal_enrollment.enrollment_kind = "open_enrollment"
      renewal_enrollment.kind = "employer_sponsored"

      if @census_employee.renewal_benefit_group_assignment.blank?
        @census_employee.add_renew_benefit_group_assignment(@renewing_plan_year.benefit_groups.first)
      end

      benefit_group_assignment = @census_employee.renewal_benefit_group_assignment

      benefit_group_assignment = @census_employee.renewal_benefit_group_assignment
      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on

      renewal_enrollment.waiver_reason = waived_enrollment.try(:waiver_reason) || "I do not have other coverage"
      renewal_enrollment.renew_waived
      renewal_enrollment.submitted_at = TimeKeeper.datetime_of_record

      if renewal_enrollment.save
        return
      else
        message = "Unable to save waived renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

          Rails.logger.error { message }

        raise FamilyEnrollmentRenewalFactoryError, message
      end
    end

    def renewal_builder(active_enrollment)
      renewal_enrollment = family.active_household.hbx_enrollments.new
      renewal_enrollment = assign_common_attributes(active_enrollment, renewal_enrollment)
      renewal_enrollment.renew_enrollment
      renewal_enrollment
    end

    def save_renewal_enrollment(renewal_enrollment, active_enrollment)
      if renewal_enrollment.save
        renewal_enrollment
      else
        message = "Enrollment: #{active_enrollment.id}, \n" \
        "Unable to save renewal enrollment: #{renewal_enrollment.inspect}, \n" \
          "Error(s): \n #{renewal_enrollment.errors.map{|k,v| "#{k} = #{v}"}.join(" & \n")} \n"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end
    end

    def assign_common_attributes(active_enrollment, renewal_enrollment)
      common_attributes = %w(coverage_household_id coverage_kind changing broker_agency_profile_id
          writing_agent_id original_application_type kind special_enrollment_period_id
        )
      common_attributes.each do |attr|
         renewal_enrollment.send("#{attr}=", active_enrollment.send(attr))
      end

      renewal_enrollment.plan_id = active_enrollment.plan.renewal_plan(renewing_plan_year.start_on).id if active_enrollment.plan.present?
      renewal_enrollment
    end

    def clone_ivl_enrollment
      # consumer_role_id
      # elected_amount
      # elected_premium_credit
      # applied_premium_credit
      # elected_aptc_amount
      # applied_aptc_amount

      # renewal_enrollment.renew_coverage
    end

    def clone_shop_enrollment(active_enrollment, renewal_enrollment)
      # Find and associate with new ER benefit group

      if @census_employee.renewal_benefit_group_assignment.blank?
        @census_employee.add_renew_benefit_group_assignment(@renewing_plan_year.benefit_groups.first)
      end

      benefit_group_assignment = @census_employee.renewal_benefit_group_assignment

      if benefit_group_assignment.blank?
        message = "Unable to find benefit_group_assignment for census_employee: \n"\
          "census_employee: #{@census_employee.full_name} "\
          "id: #{@census_employee.id} "\
          "for hbx_enrollment #{active_enrollment.id}"

        Rails.logger.error { message }
        raise FamilyEnrollmentRenewalFactoryError, message
      end

      renewal_enrollment.benefit_group_assignment_id = benefit_group_assignment.id
      renewal_enrollment.benefit_group_id = benefit_group_assignment.benefit_group_id

      renewal_enrollment.employee_role_id = active_enrollment.employee_role_id
      renewal_enrollment.effective_on = benefit_group_assignment.benefit_group.start_on
      renewal_enrollment.kind = active_enrollment.kind if active_enrollment.is_cobra_status?
      # Set the HbxEnrollment to proper state

      # Renew waiver status
      if active_enrollment.is_coverage_waived?
        renewal_enrollment.waiver_reason = active_enrollment.waiver_reason
        renewal_enrollment.waive_coverage
      end

      renewal_enrollment.hbx_enrollment_members = clone_enrollment_members(active_enrollment, renewal_enrollment)
      renewal_enrollment
    end

    # clone enrollment members if relationship offered in renewal plan year and active in current hbxenrollment
    def clone_enrollment_members(active_enrollment, renewal_enrollment)
      hbx_enrollment_members = active_enrollment.hbx_enrollment_members
      hbx_enrollment_members.reject!{|member| !is_relationship_offered_and_member_covered?(member,renewal_enrollment) }
      hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
        members << HbxEnrollmentMember.new({
          applicant_id: hbx_enrollment_member.applicant_id,
          eligibility_date: @plan_year_start_on,
          coverage_start_on: @plan_year_start_on,
          is_subscriber: hbx_enrollment_member.is_subscriber
        })
      end
    end

    # relationship_benefits of renewal plan year
    def renewal_relationship_benefits(renewal_enrollment)
      benefit_group = @census_employee.renewal_benefit_group_assignment.benefit_group
      if renewal_enrollment.coverage_kind == "health"
        benefit_group.relationship_benefits.select(&:offered).map(&:relationship)
      else
        benefit_group.dental_relationship_benefits.select(&:offered).map(&:relationship)
      end
    end

    # relationship offered in renewal plan year and member active in enrollment.
    def is_relationship_offered_and_member_covered?(member,renewal_enrollment)
      return true if renewal_enrollment.composite_rated?
      relationship = PlanCostDecorator.benefit_relationship(member.primary_relationship)
      relationship = "child_over_26" if relationship == "child_under_26" && member.person.age_on(@plan_year_start_on) >= 26
      (renewal_relationship_benefits(renewal_enrollment).include?(relationship) && member.is_covered_on?(@plan_year_start_on - 1.day))
    end

    # Validate enrollment membership against benefit package-covered relationships
    def family_eligibility(active_enrollment, renewal_enrollment)

      coverage_household.coverage_household_members.each do |coverage_member|
        enrollment_member = HbxEnrollmentMember.new_from(coverage_household_member: coverage_member)
        enrollment_member.eligibility_date = enrollment.effective_on
        enrollment_member.coverage_start_on = enrollment.effective_on
        renewal_enrollment.hbx_enrollment_members << enrollment_member
      end

      renewal_enrollment.hbx_enrollment_members
    end

    def set_instance_variables
      @family = enrollment.family
      @census_employee = enrollment.employee_role.census_employee
      @employer = enrollment.employee_role.employer_profile
      @renewing_plan_year = @employer.renewing_published_plan_year
    end
  end

class FamilyEnrollmentRenewalFactoryError < StandardError; end
end


