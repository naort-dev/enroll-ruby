require 'rails_helper'

module SponsoredBenefits
  RSpec.describe Organizations::PlanDesignProposals::ContributionsController, type: :controller, dbclean: :around_each do
    render_views
    routes { SponsoredBenefits::Engine.routes }
    let(:valid_session) { {} }
    let(:current_person) { double(:current_person) }
    let(:active_user) { double(:has_hbx_staff_role? => false) }
    let(:broker_role) { double(:broker_role, id: 3) }

		let(:plan_design_organization) do
			FactoryGirl.create :sponsored_benefits_plan_design_organization,
				owner_profile_id: owner_profile.id,
				sponsor_profile_id: sponsor_profile.id
		end

		let(:plan_design_proposal) do
			FactoryGirl.create(:plan_design_proposal,
				:with_profile,
				plan_design_organization: plan_design_organization
			).tap do |proposal|
				sponsorship = proposal.profile.benefit_sponsorships.first
				sponsorship.initial_enrollment_period = benefit_sponsorship_enrollment_period
				sponsorship.save
			end
		end

		let(:proposal_profile) { plan_design_proposal.profile }

		let(:benefit_sponsorship_enrollment_period) do
			begin_on = SponsoredBenefits::BenefitApplications::BenefitApplication.calculate_start_on_dates[0]
			end_on = begin_on + 1.year - 1.day
			begin_on..end_on
		end

		let(:benefit_sponsorship) { proposal_profile.benefit_sponsorships.first }

		let(:benefit_application) { FactoryGirl.create(:plan_design_benefit_application,
			:with_benefit_group,
			benefit_sponsorship: benefit_sponsorship
		)}

		let(:benefit_group) { benefit_application.benefit_groups.first }

		let(:owner_profile) { broker_agency_profile }
		let(:broker_agency) { owner_profile.organization }
		let(:general_agency_profile) { ga_profile }

		let(:employer_profile) { sponsor_profile }
		let(:benefit_sponsor) { sponsor_profile.organization }

		let(:plan_design_census_employee) { FactoryGirl.create(:plan_design_census_employee,
			benefit_sponsorship_id: benefit_sponsorship.id
		)}

		let(:organization) { plan_design_organization.sponsor_profile.organization }

		let!(:current_effective_date) do
			(TimeKeeper.date_of_record + 2.months).beginning_of_month.prev_year
		end

		let!(:broker_agency_profile) do
			if Settings.aca.state_abbreviation == "DC" # toDo
				FactoryGirl.create(:broker_agency_profile)
			else
				FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
					:with_site,
					:with_broker_agency_profile
				).profiles.first
			end
		end

		let!(:sponsor_profile) do
			if Settings.aca.state_abbreviation == "DC" # toDo
				FactoryGirl.create(:employer_profile)
			else
				FactoryGirl.create(:benefit_sponsors_organizations_general_organization,
					:with_site,
					:with_aca_shop_cca_employer_profile
				).profiles.first
			end
		end

    let!(:relationship_benefit) { benefit_group.relationship_benefits.first }

    before do
      allow(subject).to receive(:current_person).and_return(current_person)
      allow(subject).to receive(:active_user).and_return(active_user)
      allow(current_person).to receive(:broker_role).and_return(broker_role)
      allow(broker_role).to receive(:broker_agency_profile_id).and_return(broker_agency_profile.id)
      allow(broker_role).to receive(:benefit_sponsors_broker_agency_profile_id).and_return(broker_agency_profile.id)
      get :index, {
        plan_design_proposal_id: plan_design_proposal.id,
        benefit_group: {
          reference_plan_id: benefit_group.reference_plan_id.to_s,
          plan_option_kind: benefit_group.plan_option_kind,
          relationship_benefits_attributes: [{ "0" => {
            relationship: relationship_benefit.relationship,
            premium_pct: relationship_benefit.premium_pct,
            offered: relationship_benefit.offered
          }}]
        },
        format: :js
      }, valid_session
    end

    it 'works' do
      expect(response.body).to match(/#{benefit_group.reference_plan.name}/)
    end
  end
end
