require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::PlanDesignOrganizationsController < ApplicationController
    include Config::AcaConcern
    include Config::BrokerAgencyHelper

    before_action :load_broker_agency_profile, only: [:new, :create]

    def new
      init_organization
    end

    def create
      old_broker_agency_profile = ::BrokerAgencyProfile.find(params[:broker_agency_id])
      broker_agency_profile = SponsoredBenefits::Organizations::BrokerAgencyProfile.find_or_initialize_broker_profile(old_broker_agency_profile).broker_agency_profile
      broker_agency_profile.plan_design_organizations.new(organization_params.merge(owner_profile_id: old_broker_agency_profile.id))

      if broker_agency_profile.save
        flash[:success] = "Prospect Employer Added Successfully."
        redirect_to employers_organizations_broker_agency_profile_path(@broker_agency_profile)
      else
        init_organization
        render :new
      end
    end

    def edit
      @organization = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:id])
      get_sic_codes
    end

    def update
      pdo = SponsoredBenefits::Organizations::PlanDesignOrganization.find(params[:id])
      pdo.assign_attributes(organization_params)

      if pdo.save
        flash[:success] = "Prospect Employer Updated Successfully."
        redirect_to employers_organizations_broker_agency_profile_path(pdo.broker_agency_profile)
      else
        render :edit
      end
    end

  private

    def load_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:broker_agency_id])
    end

    def init_organization
      @organization = ::Forms::EmployerProfile.new
      get_sic_codes
    end

    def find_broker_agency_profile
      @broker_agency_profile = ::BrokerAgencyProfile.find(params[:plan_design_organization_id])
    end

    def organization_params
      params.require(:organization).permit(
        :legal_name, :dba, :entity_kind, :sic_code,
        :office_locations_attributes => [
          {:address_attributes => [:kind, :address_1, :address_2, :city, :state, :zip, :county]},
          {:phone_attributes => [:kind, :area_code, :number, :extension]},
          {:email_attributes => [:kind, :address]},
          :is_primary
        ]
      )
    end

    def get_sic_codes
      @grouped_options = {}
      ::SicCode.all.group_by(&:industry_group_label).each do |industry_group_label, sic_codes|
        @grouped_options[industry_group_label] = sic_codes.collect{|sc| ["#{sc.sic_label} - #{sc.sic_code}", sc.sic_code]}
      end
    end
  end
end
