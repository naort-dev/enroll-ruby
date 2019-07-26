module Enrollments
  module Replicator
    class Reinstatement

      attr_accessor :base_enrollment, :new_effective_date, :new_aptc

      def initialize(enrollment, effective_date, new_aptc = nil)
        @base_enrollment = enrollment
        @new_effective_date = effective_date
        @new_aptc = new_aptc
      end

      def benefit_application
        base_enrollment.sponsored_benefit_package.benefit_application
      end

      def census_employee
        base_enrollment.benefit_group_assignment.census_employee
      end

      def reinstate_under_renewal_py?
        new_effective_date > benefit_application.end_on
      end

      def renewal_benefit_application
        benefit_application.benefit_sponsorship.benefit_applications.renewing.published_benefit_applications_by_date(new_effective_date).first
      end

      def renewal_benefit_group_assignment
        assignment = census_employee.renewal_benefit_group_assignment
        if assignment.blank?
          if census_employee.active_benefit_group_assignment.blank?
            census_employee.save
          end
          if renewal_benefit_application == census_employee.published_benefit_group_assignment.benefit_application
            assignment = census_employee.published_benefit_group_assignment
          end
        end
        assignment
      end

      def reinstatement_plan
        if reinstate_under_renewal_py?
          base_enrollment.product.renewal_product
        else
          base_enrollment.product
        end
      end

      def reinstatement_benefit_group_assignment
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.id
        else
          base_enrollment.benefit_group_assignment_id
        end
      end

      def reinstatement_sponsored_benefit_package
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.benefit_group
        else
          base_enrollment.sponsored_benefit_package
        end
      end

      def reinstatement_sponsored_benefit
        if base_enrollment.coverage_kind == 'health'
          reinstatement_sponsored_benefit_package.health_sponsored_benefit
        else
          reinstatement_sponsored_benefit_package.dental_sponsored_benefit
        end
      end

      def reinstate_rating_area
        if reinstate_under_renewal_py?
          renewal_benefit_group_assignment.benefit_application.recorded_rating_area_id
        else
          base_enrollment.rating_area_id
        end
      end

      def renewal_plan_offered_by_er?(renewal_plan)
        reinstatement_sponsored_benefit.products(new_effective_date).map(&:_id).include?(renewal_plan.id)
      end

      def can_be_reinstated?
        if reinstate_under_renewal_py?
          if !renewal_plan_offered_by_er?(reinstatement_plan)
            raise "Unable to reinstate enrollment: your Employer Sponsored Benefits no longer offerring the plan (#{reinstatement_plan.name})."
          end
        end
        true
      end

      def build
        family = base_enrollment.family
        reinstated_enrollment = HbxEnrollment.new
        reinstated_enrollment.family = family
        reinstated_enrollment.household = family.active_household


        reinstated_enrollment.effective_on = new_effective_date
        reinstated_enrollment.coverage_kind = base_enrollment.coverage_kind
        reinstated_enrollment.enrollment_kind = base_enrollment.enrollment_kind
        reinstated_enrollment.kind = base_enrollment.kind
        reinstated_enrollment.predecessor_enrollment_id = base_enrollment.id
        reinstated_enrollment.hbx_enrollment_members = clone_hbx_enrollment_members

        if base_enrollment.is_shop?
          if can_be_reinstated?
            reinstated_enrollment.employee_role_id = base_enrollment.employee_role_id
            reinstated_enrollment.benefit_group_assignment_id = reinstatement_benefit_group_assignment
            reinstated_enrollment.sponsored_benefit_package_id = reinstatement_sponsored_benefit_package.id
            reinstated_enrollment.sponsored_benefit_id = reinstatement_sponsored_benefit.id
            reinstated_enrollment.benefit_sponsorship_id = base_enrollment.benefit_sponsorship_id
            reinstated_enrollment.product_id = reinstatement_plan.id
            reinstated_enrollment.rating_area_id = reinstate_rating_area
            reinstated_enrollment.issuer_profile_id = reinstatement_plan.issuer_profile_id
          end
        elsif base_enrollment.is_ivl_by_kind? && new_aptc
          # Change in APTC path for IVL
          # Gather information needed
          aptc_ratio_by_member = family.active_household.latest_active_tax_household.aptc_ratio_by_member
          percent_sum_for_all_enrolles = duplicate_hbx.hbx_enrollment_members.inject(0.0) { |sum, member| sum + aptc_ratio_by_member[member.applicant_id.to_s] || 0.0 }
          max_aptc = family.active_household.latest_active_tax_household_with_year(year).latest_eligibility_determination.max_aptc.to_f

          # Update enrollment basics
          reinstated_enrollment.product_id = base_enrollment.product_id
          reinstated_enrollment.consumer_role_id = base_enrollment.consumer_role_id

          # Update applied APTC on enrollment
          reinstated_enrollment.applied_aptc_amount = new_aptc

          # Update elected APTC percent on enrollment - To do: DOUBLE CHECK THIS CALCULATION -
          reinstated_enrollment.elected_aptc_pct = new_aptc / max_aptc

          # Update applied APTC for each enrollment member
          duplicate_hbx.hbx_enrollment_members.each do |mem|
            aptc_pct_for_member = aptc_ratio_by_member[mem.applicant_id.to_s] || 0.0
            mem.applied_aptc_amount = new_aptc * aptc_pct_for_member / percent_sum_for_all_enrolles
          end

          # To do for this path: Handle enrollment state & handle 15th of month rule for effective date (outside of service, probably)
        end

        reinstated_enrollment
      end

      def member_coverage_start_date(hbx_enrollment_member)
        if base_enrollment.is_shop? && reinstate_under_renewal_py?
          new_effective_date
        elsif base_enrollment.is_ivl_by_kind? && new_aptc
          # If "copying" an enrollment to edit APTC, then we keep the coverage_start_on from the old member object since we aren't changing the plan
          hbx_enrollment_member.coverage_start_on
        else
          hbx_enrollment_member.coverage_start_on || base_enrollment.effective_on || new_effective_date
        end
      end

      def clone_hbx_enrollment_members
        base_enrollment.hbx_enrollment_members.inject([]) do |members, hbx_enrollment_member|
          members << HbxEnrollmentMember.new({
                                                 applicant_id: hbx_enrollment_member.applicant_id,
                                                 eligibility_date: new_effective_date,
                                                 coverage_start_on: member_coverage_start_date(hbx_enrollment_member),
                                                 is_subscriber: hbx_enrollment_member.is_subscriber
                                             })
        end
      end
    end
  end
end