module SponsoredBenefits
  module Organizations
    class PlanDesignProposals::ContributionsController < ApplicationController

      def index
        puts 'started'
        @plan = ::Plan.find(benefit_group.reference_plan_id)
        puts 'find'
        if benefit_group.sole_source?
          benefit_group.build_estimated_composite_rates
        end
        benefit_group.set_bounding_cost_plans
        @employer_contribution_amount = benefit_group.monthly_employer_contribution_amount(@plan)
        @min_employee_cost = benefit_group.monthly_min_employee_cost
        @max_employee_cost = benefit_group.monthly_max_employee_cost

        puts 'employee_costs'
        @benefit_group_costs = benefit_group.employee_costs_for_reference_plan
        puts 'employee_costs done'
      end

      private
        helper_method :plan_design_proposal, :benefit_group, :kind

        def plan_design_proposal
          @plan_design_proposal ||= PlanDesignProposal.find(params[:plan_design_proposal_id])
        end

        def sponsorship
          @sponsorship ||= plan_design_proposal.profile.benefit_sponsorships.first
        end

        def kind
          @kind ||= params[:benefit_group][:kind]
        end

        def benefit_group
          return @benefit_group if defined? @benefit_group
          @benefit_group ||= sponsorship.benefit_applications.first.benefit_groups.build(benefit_group_params)

          # This always take one benefit group at a time to calculate costs. we never save this to database.
          if @benefit_group.reference_plan.dental?
            @benefit_group.dental_relationship_benefits = @benefit_group.relationship_benefits
          end
          @benefit_group
        end

        def benefit_group_params
          params.require(:benefit_group).permit(
                      :reference_plan_id,
                      :plan_option_kind,
                      :elected_dental_plans,
                      relationship_benefits_attributes: [:relationship, :premium_pct, :offered],
                      composite_tier_contributions_attributes: [:composite_rating_tier, :employer_contribution_percent, :offered]
          )
        end
    end
  end
end
