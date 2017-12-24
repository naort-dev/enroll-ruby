module Queries
  class PlanDesignEmployeeQuery
    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      # @employer_profile = EmployerProfile.find(@custom_attributes[:id])
      @benefit_sponsorship = SponsoredBenefits::BenefitSponsorships::BenefitSponsorship.find(@custom_attributes[:id])
    end

    def build_scope()
      return [] if @benefit_sponsorship.blank?
      # case @custom_attributes[:employers]
      #   when "active"
      #     @employer_profile.census_employees.active
      #   when "active_alone"
      #     @employer_profile.census_employees.active_alone
      #   when "by_cobra"
      #     @employer_profile.census_employees.by_cobra
      #   when "terminated"
      #     @employer_profile.census_employees.terminated
      #   when "all"
      #     @employer_profile.census_employees
      #   else
      #     @employer_profile.census_employees.active_alone
      # end

      @benefit_sponsorship.census_employees
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
      Family
    end

    def size
      build_scope.count
    end
  end
end