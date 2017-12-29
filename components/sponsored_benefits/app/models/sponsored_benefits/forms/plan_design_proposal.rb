module SponsoredBenefits
  module Forms
    class PlanDesignProposal

      include ActiveModel::Model
      include ActiveModel::Validations

      attr_reader :title, :effective_date, :zip_code, :county, :sic_code, :quote_date, :plan_option_kind, :metal_level_for_elected_plan
      attr_reader :profile
      attr_reader :plan_design_organization
      attr_reader :proposal

      validates_presence_of :title, :effective_date, :sic_code, :county, :zip_code

      def initialize(attrs = {})
        assign_wrapper_attributes(attrs)
        ensure_proposal
        ensure_profile
        ensure_sic_zip_county
        ensure_benefit_group
      end

      def assign_wrapper_attributes(attrs = {})
        attrs.each_pair do |k,v|
          self.send("#{k}=", v)
        end
      end

      def organization=(val)
        @plan_design_organization = val
      end

      def profile=(attrs)
      end

      def title=(val)
        @title = val
      end

      def effective_date=(val)
        @effective_date = Date.strptime(val, "%Y-%m-%d")
      end

      def proposal_id=(val)
        return if val.blank?
        @proposal = @plan_design_organization.plan_design_proposals.detect{|proposal| proposal.id.to_s == val }
        if @proposal.present?
          @profile = @proposal.profile
          prepopulate_attributes
        end
      end

      def prepopulate_attributes
        @title = @proposal.title
        @effective_date = @profile.benefit_sponsorships.first.initial_enrollment_period.min.strftime("%Y-%m-%d")
        @quote_date = @proposal.updated_at.strftime("%m/%d/%Y")
      end

      def ensure_proposal
        @proposal = @plan_design_organization.plan_design_proposals.build unless @proposal.present?
      end

      def ensure_sic_zip_county
        @sic_code = @plan_design_organization.sic_code
        if location = @plan_design_organization.office_locations.first
          @zip_code = location.address.zip
          @county = location.address.county
        end
      end

      def ensure_profile
        if @profile.blank?
          @profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new
          sponsorship = @profile.benefit_sponsorships.first
          sponsorship.benefit_applications.build
        end
        sponsorship = @profile.benefit_sponsorships.first
        if sponsorship.benefit_applications.empty?
          sponsorship.benefit_applications.build
        end
      end

      def ensure_benefit_group
        sponsorship = @profile.benefit_sponsorships.first
        application = sponsorship.benefit_applications.first
        # Commented out due to validation errors on Benefit Groups
        # application.benefit_groups.build
        # application.benefit_groups.first.build_relationship_benefits
        # application.benefit_groups.first.build_composite_tier_contributions
      end

      def save
        initial_enrollment_period = @effective_date..(@effective_date.next_year.prev_day)

        if @proposal.persisted?
          @proposal.assign_attributes(title: @title)
        else
          profile = SponsoredBenefits::Organizations::AcaShopCcaEmployerProfile.new({sic_code: @sic_code})
          @proposal = @plan_design_organization.plan_design_proposals.build({title: @title, profile: profile})
        end

        sponsorship = @proposal.profile.benefit_sponsorships.first
        sponsorship.assign_attributes({initial_enrollment_period: initial_enrollment_period, annual_enrollment_period_begin_month: @effective_date.month})
        if sponsorship.present?
          enrollment_dates = BenefitApplications::BenefitApplication.enrollment_timetable_by_effective_date(@effective_date)
          benefit_application = (sponsorship.benefit_applications.first || sponsorship.benefit_applications.build)
          benefit_application.effective_period= enrollment_dates[:effective_period]
          benefit_application.open_enrollment_period= enrollment_dates[:open_enrollment_period]
        end

        @proposal.save
      end
    end
  end
end
