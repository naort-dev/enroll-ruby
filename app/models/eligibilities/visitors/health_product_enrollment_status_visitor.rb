# frozen_string_literal: true

module Eligibilities
  module Visitors
    # Use Visitor Development Pattern to access models and determine Non-ESI
    # eligibility status for a Family Financial Assistance Application's Applicants
    class HealthProductEnrollmentStatusVisitor < Visitor
      attr_accessor :evidence, :subject, :evidence_item, :effective_date

      def call
        enrollments = hbx_enrollment_instances_for(subject, effective_date)
        unless enrollments.present?
          @evidence = Hash[evidence_item[:key], {}]
          return
        end
        enrollments.each { |enrollment| enrollment.accept(self) }
      end

      def visit(enrollment_member)
        return unless enrollment_member.applicant_id == subject.id
        @evidence = evidence_state_for(enrollment_member)
      end

      private

      def hbx_enrollment_instances_for(subject, effective_date)
        HbxEnrollment
          .where(
            :family_id => subject.family.id,
            :effective_on.gte => effective_date.beginning_of_year,
            :effective_on.lte => effective_date.end_of_year + 3.months
          )
          .individual_market
          .by_health
          .enrolled_and_renewing
      end

      def evidence_state_for(enrollment_member)
        enrollment = enrollment_member._parent

        evidence_state_attributes = {
          status: 'determined',
          meta: {
            coverage_start_on: enrollment_member.coverage_start_on,
            csr_variant_id: enrollment.product.csr_variant_id,
            enrollment_status: enrollment.aasm_state,
            enrollment_gid: enrollment.to_global_id.uri.to_s
          },
          is_satisfied: true,
          verification_outstanding: false,
          visited_at: DateTime.now,
          due_on: nil,
          evidence_gid: enrollment_member.to_global_id.uri
        }

        Hash[evidence_item[:key].to_sym, evidence_state_attributes]
      end
    end
  end
end
