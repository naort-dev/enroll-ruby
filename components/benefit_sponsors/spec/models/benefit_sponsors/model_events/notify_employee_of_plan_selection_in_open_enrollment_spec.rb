require 'rails_helper'

module BenefitSponsors
  RSpec.describe 'ModelEvents::NotifyEmployeeOfPlanSelectionInOpenEnrollment', dbclean: :around_each  do
    let(:current_effective_date)  { TimeKeeper.date_of_record }

    let(:person)       { FactoryGirl.create(:person, :with_family, :with_employee_role) }
    let(:family)       { person.primary_family }
    let(:employee_role)     { person.employee_roles.first }
    let!(:census_employee)  { FactoryGirl.create(:benefit_sponsors_census_employee, benefit_sponsorship: benefit_sponsorship, employer_profile: employer_profile, first_name: person.first_name, last_name: person.last_name ) }

    let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)     { organization.employer_profile }
    let(:benefit_sponsorship)  { employer_profile.add_benefit_sponsorship }
    let!(:benefit_market) { site.benefit_markets.first }
    let!(:benefit_market_catalog) { 
      create(:benefit_markets_benefit_market_catalog, :with_product_packages,
        benefit_market: benefit_market,
        title: "SHOP Benefits for #{current_effective_date.year}",
        application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
    }
    let!(:benefit_application) {
      application = FactoryGirl.create(:benefit_sponsors_benefit_application, :with_benefit_sponsor_catalog, :with_benefit_package, benefit_sponsorship: benefit_sponsorship)
      application.benefit_sponsor_catalog.save!
      application
    }
    let!(:model_instance) { 
      hbx_enrollment = FactoryGirl.create(:hbx_enrollment, :with_enrollment_members, :with_product, 
                          household: family.active_household, 
                          aasm_state: "shopping",
                          submitted_at: benefit_application.open_enrollment_period.max,
                          rating_area_id: benefit_application.recorded_rating_area_id,
                          sponsored_benefit_id: benefit_application.benefit_packages.first.health_sponsored_benefit.id,
                          sponsored_benefit_package_id: benefit_application.benefit_packages.first.id,
                          benefit_sponsorship_id:benefit_application.benefit_sponsorship.id, 
                          employee_role_id: employee_role.id
                          ) 
      hbx_enrollment.benefit_sponsorship = benefit_sponsorship
      hbx_enrollment.save!
      hbx_enrollment
    }

    before do
      employee_role.update_attributes(census_employee_id: census_employee.id)
    end

    describe "NoticeTrigger" do
      context "when employee selects coverage in Open Enrollment" do
        subject { BenefitSponsors::Observers::HbxEnrollmentObserver.new }
        let(:model_event) { ::BenefitSponsors::ModelEvents::ModelEvent.new(:application_coverage_selected, model_instance, {}) }

        it "should trigger notice event" do
          expect(subject.notifier).to receive(:notify) do |event_name, payload|
            expect(event_name).to eq "acapi.info.events.employee.notify_employee_of_plan_selection_in_open_enrollment"
            expect(payload[:event_object_kind]).to eq 'HbxEnrollment'
            expect(payload[:event_object_id]).to eq model_instance.id.to_s
          end
          subject.notifications_send(model_instance, model_event)
        end
      end
    end

    describe "NoticeBuilder" do

      let(:data_elements) {
        [
          "employee_profile.notice_date",
          "employee_profile.first_name",
          "employee_profile.last_name",
          "employee_profile.employer_name",
          "employee_profile.enrollment.coverage_end_on",
          "employee_profile.enrollment.coverage_kind",
          "employee_profile.enrollment.plan_name"
        ]
      }

      let(:recipient) { "Notifier::MergeDataModels::EmployeeProfile" }
      let(:template)  { Notifier::Template.new(data_elements: data_elements) }
      let(:payload)   { {
          "event_object_kind" => "HbxEnrollment",
          "event_object_id" => model_instance.id
      } }
      let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
      let(:merge_model) { subject.construct_notice_object }

      before do
        allow(subject).to receive(:resource).and_return(employee_role)
        allow(subject).to receive(:payload).and_return(payload)
        employee_role.update_attributes(census_employee_id: census_employee.id) 
      end

      it "should return merge model" do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it "should return notice_date" do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it "should return employee first_name" do
        expect(merge_model.first_name).to eq model_instance.census_employee.first_name
      end

      it "should return employee last_name" do
        expect(merge_model.last_name).to eq model_instance.census_employee.last_name
      end

      it "should return employer legal_name" do
        expect(merge_model.employer_name).to eq model_instance.employer_profile.legal_name
      end

      it "should return enrollment coverage_kind" do
        expect(merge_model.enrollment.coverage_kind).to eq model_instance.coverage_kind
      end

      it "should return plan name" do
        expect(merge_model.enrollment.plan_name).to eq model_instance.product.name
      end
    end
  end
end