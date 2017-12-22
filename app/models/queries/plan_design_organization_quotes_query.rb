module Queries
  class PlanDesignOrganizationQuotesQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @plan_design_organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(@custom_attributes[:organization_id])
      @plan_design_proposals = @plan_design_organization.plan_design_proposals
    end

    def build_scope()
      return [] if @plan_design_proposals.nil?
      # case @custom_attributes[:clients]
      # when "active_clients"
      #   @plan_design_organization.active_clients
      # when "inactive_clients"
      #   @plan_design_organization.inactive_clients
      # when "prospect_employers"
      #   @plan_design_organization.prospect_employers
      # else
      #   if @search_string.present?
      #     @plan_design_organization.datatable_search(@search_string)
      #   else
      #     @plan_design_organization
      #   end
      # end
      @plan_design_proposals
    end

    def skip(num)
      build_scope.skip(num)
    end

    def limit(num)
      build_scope.limit(num)
    end

    def order_by(var)
      @order_by = var
      self
    end

    def any?
      build_scope.each do |e|
        return if yield(e)
      end
    end

    def klass
      SponsoredBenefits::Organizations::PlanDesignProposal
    end

    def size
      build_scope.count
    end
  end
end
