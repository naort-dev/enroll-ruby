class Exchanges::EmployerApplicationsController < ApplicationController
  include Pundit

  before_action :can_modify_plan_year?, only: [:terminate, :cancel]
  before_action :check_hbx_staff_role, except: :get_term_reasons
  before_action :find_benefit_sponsorship, except: :get_term_reasons

  def index
    @element_to_replace_id = params[:employers_action_id]
  end

  def terminate
    @application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
    end_on = Date.strptime(params[:end_on], "%m/%d/%Y")
    termination_kind = params['term_kind']
    termination_reason = params['term_reason']
    transmit_to_carrier = (params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true) ? true : false
    @service = BenefitSponsors::Services::BenefitApplicationActionService.new(@application, { end_on: end_on, termination_kind: termination_kind, termination_reason: termination_reason, transmit_to_carrier: transmit_to_carrier })
    result, application, errors = @service.terminate_application
    if result
      flash[:notice] = "#{@benefit_sponsorship.organization.legal_name}'s Application terminated successfully."
    else
      flash[:error] = "#{@benefit_sponsorship.organization.legal_name}'s Application could not be terminated due to #{errors.inject(''){|memo, error| '#{memo}<li>#{error}</li>'}.html_safe}"
    end
    render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
  end

  def cancel
    @application = @benefit_sponsorship.benefit_applications.find(params[:employer_application_id])
    transmit_to_carrier = (params['transmit_to_carrier'] == "true" || params['transmit_to_carrier'] == true) ? true : false
    @service = BenefitSponsors::Services::BenefitApplicationActionService.new(@application, { transmit_to_carrier: transmit_to_carrier })
    result, application, errors = @service.cancel_application
    if result
      flash[:notice] = "#{@benefit_sponsorship.organization.legal_name}'s Application canceled successfully."
    else
      flash[:error] = "#{@benefit_sponsorship.organization.legal_name}'s Application could not be canceled due to #{errors.inject(''){|memo, error| '#{memo}<li>#{error}</li>'}.html_safe}"
    end
    render :js => "window.location = #{exchanges_hbx_profiles_root_path.to_json}"
  end

  def get_term_reasons
    @reasons = if params[:reason_type_id] == "term_actions_nonpayment"
      BenefitSponsors::BenefitApplications::BenefitApplication::NON_PAYMENT_TERM_REASONS
    else
      BenefitSponsors::BenefitApplications::BenefitApplication::VOLUNTARY_TERM_REASONS
    end
    render json: @reasons
  end

  def reinstate

  end

  private

  def can_modify_plan_year?
    authorize HbxProfile, :can_modify_plan_year?
  end

  def check_hbx_staff_role
    unless current_user.has_hbx_staff_role?
      redirect_to root_path, :flash => { :error => "You must be an HBX staff member" }
    end
  end

  def find_benefit_sponsorship
    @benefit_sponsorship = BenefitSponsors::BenefitSponsorships::BenefitSponsorship.find(params[:employer_id])
  end
end