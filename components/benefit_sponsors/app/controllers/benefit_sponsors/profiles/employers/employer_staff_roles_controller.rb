module BenefitSponsors
  module Profiles
    class Employers::EmployerStaffRolesController < ::ApplicationController

      #TODO for employer profile and authorization
      # before_action :check_access_to_employer_profile, :updateable?

      def edit
        @employer_profile = find_employer_profile
        @staff = Person.staff_for_benefit_sponsors_employer_including_pending(@employer_profile)
        @add_staff = params[:add_staff]
        respond_to do |format|
          format.html { render "benefit_sponsors/profiles/employers/employer_profiles/edit.html.erb" }
          format.js
        end
      end

      def create
        dob = DateTime.strptime(params[:dob], '%m/%d/%Y').try(:to_date)
        employer_profile = find_employer_profile
        first_name = (params[:first_name] || '').strip
        last_name = (params[:last_name] || '').strip
        email = params[:email]
        @status, @result = Person.add_benefit_sponsors_employer_staff_role(first_name, last_name, dob, email, employer_profile)
        flash[:error] = ('Role was not added because ' + @result) unless @status
        redirect_to edit_profiles_employers_employer_profile_path(employer_profile)
      end

      #new person registered with existing organization is pending for staff role approval
      #below action is triggered from employer to approve for staff role
      def approve
        employer_profile = find_employer_profile
        person = Person.find(params[:staff_id])
        role = person.benefit_sponsors_employer_staff_roles.detect{|role| role.is_applicant? && role.employer_profile_id.to_s == params[:id]}
        if role && role.approve && role.save!
          flash[:notice] = 'Role is approved'
        else
          flash[:error] = 'Please contact HBX Admin to report this error'
        end
        redirect_to edit_profiles_employers_employer_profile_path(employer_profile)
      end

      # For this person find an employer_staff_role that match this employer_profile_id and mark the role inactive
      def destroy
        employer_profile_id = params[:id]
        employer_profile = find_employer_profile
        staff_id = params[:staff_id]
        staff_list = Person.staff_for_benefit_sponsors_employer(employer_profile).map(&:id)
        if staff_list.count == 1 && staff_list.first.to_s == staff_id
          flash[:error] = 'Please add another staff role before deleting this role'
        else
          @status, @result = Person.deactivate_benefit_sponsors_employer_staff_role(staff_id, employer_profile_id)
          @status ? (flash[:notice] = 'Staff role was deleted') : (flash[:error] = ('Role was not deactivated because '  + @result))
        end
        redirect_to edit_profiles_employers_employer_profile_path(employer_profile)
      end

      private

      def updateable?
        #authorize EmployerProfile, :updateable?
      end

      # Check to see if current_user is authorized to access the submitted employer profile
      def check_access_to_employer_profile
        # employer_profile = find_employer_profile
        # policy = ::AccessPolicies::EmployerProfile.new(current_user)
        # policy.authorize_edit(employer_profile, self)
      end

      def find_employer_profile
        @organization = BenefitSponsors::Organizations::Organization.employer_profiles.where(:"profiles._id" => BSON::ObjectId.from_string(params[:id])).first
        employer_profile = @organization.employer_profile
      end
    end
  end
end



