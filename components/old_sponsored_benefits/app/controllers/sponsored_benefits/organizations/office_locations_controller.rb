require_dependency "sponsored_benefits/application_controller"

module SponsoredBenefits
  class Organizations::OfficeLocationsController < ApplicationController
    class SlugLocationOwner
      def office_locations
        []
      end

      def office_locations_attributes=(vals)
      end
    end

    def new
      params.permit([:child_index, :parent_object])
      @child_index = params[:child_index]
      @parent_object = params[:parent_object]
      @slug_owner = SlugLocationOwner.new
      @office_location = SponsoredBenefits::Organizations::OfficeLocation.new
      @office_location.build_address
      @office_location.build_phone
      respond_to do |format|
        format.js
      end
    end
  end
end
