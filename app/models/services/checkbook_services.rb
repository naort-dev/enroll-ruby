require 'nokogiri'

module CheckbookServices
  class PlanComparision
    attr_accessor :census_employee
    BASE_URL =  Settings.checkbook_services.base_url
    CONGRESS_URL = Settings.checkbook_services.congress_url
    def initialize(census_employee,is_congress=false)
      @census_employee= census_employee
      is_congress ? @url = CONGRESS_URL : @url = BASE_URL+"/shop/dc/api/"
    end

    def generate_url
      begin
       puts construct_body.to_json
      @result = HTTParty.post(@url,
              :body => construct_body.to_json,
              :headers => { 'Content-Type' => 'application/json' } )
      uri = @result.parsed_response["URL"]
      if uri.present?
        return uri
      else
        raise "Unable to generate url"
      end
      rescue Exception => e
        puts "Exception #{e}"
      end
    end

    private
    def construct_body
    {
      "remote_access_key": Settings.checkbook_services.remote_access_key,
      # "remote_access_key": "cd535a89-49ea-4ea6-862f-e9558e8bef50",
      "reference_id": "9F03A78ADF324AFDBFBEF8E838770132",
      "employer_effective_date": census_employee.active_benefit_group.plan_year.start_on.strftime("%Y-%d-%m"),
      "employee_coverage_date": census_employee.active_benefit_group.plan_year.start_on.strftime("%Y-%d-%m"), #census_employee.employee_role.person.primary_family.active_household.hbx_enrollments.first.effective_on,
      "employer": {
        "state": 11,
        "county": 001
      },
      "family": build_family,
      "contribution": employer_contributions,
      "reference_plan": census_employee.employer_profile.plan_years.first.benefit_groups.first.reference_plan.hios_id,
      "filterOption":"carrier",
      "filterValue": carrier_name
      #"plans_available": census_employee.active_benefit_group.plan_year.benefit_groups.flat_map(&:elected_plans).map(&:hios_base_id)
    }
    end

    def employer_contributions
      premium_benefit_contributions = {}
      census_employee.employer_profile.plan_years.first.benefit_groups.first.relationship_benefits.each do |relationship_benefit|
        next if ["child_26_and_over","nephew_or_niece","grandchild","child_26_and_over_with_disability"].include? relationship_benefit.relationship
        relationship=  relationship_benefit.relationship == "child_under_26" ? "child" : relationship_benefit.relationship
        premium_benefit_contributions[relationship] = relationship_benefit.premium_pct.to_i
      end
      premium_benefit_contributions
    end

   def carrier_name
    elected_plans= census_employee.active_benefit_group.plan_year.benefit_groups.flat_map(&:elected_plans) 
    elected_plans.first.carrier_profile.legal_name.gsub(" ","") if elected_plans
   end



    def build_family
      family = [{'dob': census_employee.dob.strftime("%Y-%d-%m") ,'relationship': 'self'}]
      census_employee.try(:census_dependents).each do |dependent|
        next if dependent == "nephew_or_niece"
        family << {'dob': dependent.dob.strftime("%Y-%d-%m") ,'relationship': dependent.employee_relationship}
      end
      family
    end
  end
end
