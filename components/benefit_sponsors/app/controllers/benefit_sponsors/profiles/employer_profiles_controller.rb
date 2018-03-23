module BenefitSponsors
  class Profiles::EmployerProfilesController < ApplicationController
    before_action :get_site_key
    def new
      binding.pry
      if @site_key == :dc
        @profile = Organizations::AcaShopDcEmployerProfile.new
      elsif @site_key == :cca
        @profile = Organizations::AcaShopCcaEmployerProfile.new
      end
      @sponsor = Organizations::Factories::BenefitSponsorFactory.new(@profile, nil)
    end

    def create
      binding.pry
    end

    private

    def get_site_key
      @site_key = self.class.superclass.current_site.site_key
    end
  end
end
