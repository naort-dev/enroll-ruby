module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationsController < ApplicationController

      def new
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.new(application_params)
      end

      def create
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.new(application_params)
        if @benefit_application_form.save
          redirect_to new_benefit_sponsorship_benefit_application_benefit_package_path(@benefit_application_form.benefit_sponsorship, @benefit_application_form.benefit_application)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :new
        end
      end

      def edit
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.new(application_params)
        @benefit_application_form.load_attributes_from_resource
      end

      def update
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.new(application_params)
        if @benefit_application_form.save
          redirect_to benefit_sponsorship_benefit_application_benefit_packages_path(@benefit_application_form.benefit_sponsorship, @benefit_application_form.benefit_application)
        else
          flash[:error] = error_messages(@benefit_application_form)
          render :edit
        end
      end

      def recommend_dates
        @benefit_application_form = BenefitSponsors::Forms::BenefitApplicationForm.new(application_params)
      end

      private

      def error_messages(instance)
        instance.errors.full_messages.inject(""){|memo, error| "#{memo}<li>#{error}</li>"}.html_safe
      end

      def application_params
        params.permit(
          :benefit_sponsorship_id, :benefit_application_id,
          :benefit_application => [
            :id, :start_on, :end_on, :fte_count, :pte_count, :msp_count,
            :open_enrollment_start_on, :open_enrollment_end_on 
          ]
        )
      end
    end
  end
end