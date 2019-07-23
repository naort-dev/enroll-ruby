require 'rails_helper'

module BenefitSponsors
  RSpec.describe Profiles::Employers::EmployerProfilesController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }
    let!(:security_question)  { FactoryBot.create_default :security_question }

    let(:person) { FactoryBot.create(:person) }
    let(:user) { FactoryBot.create(:user, :person => person)}

    let!(:site)                  { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:benefit_sponsor)       { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
    let(:employer_profile)      { benefit_sponsor.employer_profile }
    let!(:rating_area)           { FactoryBot.create_default :benefit_markets_locations_rating_area }
    let!(:service_area)          { FactoryBot.create_default :benefit_markets_locations_service_area }
    let(:benefit_sponsorship)    { employer_profile.add_benefit_sponsorship }

    before do
      controller.prepend_view_path("../../app/views")
      person.employer_staff_roles.create! benefit_sponsor_employer_profile_id: employer_profile.id
    end

    describe "GET show_pending" do
      before do
        sign_in user
        get :show_pending
      end

      it "should render show template" do
        assert_template "show_pending"
      end

      it "should return http success" do
        assert_response :success
      end
    end

    describe "GET show" do
      let!(:employees) {
        FactoryBot.create_list(:census_employee, 2, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship)
      }
      context 'employee tab' do
        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          get :show, params: {id: benefit_sponsor.profiles.first.id.to_s, tab: 'employees'}
          allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
        end

        it "should render show template" do
          expect(response).to render_template("show")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end

      context 'accounts tab' do
        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          get :show, params: {id: benefit_sponsor.profiles.first.id.to_s, tab: 'accounts'}
          allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
        end

        it "should render show template" do
          expect(response).to render_template("show")
        end

        it "should return http success" do
          expect(response).to have_http_status(:success)
        end
      end
    end

    describe "bulk employee upload" do
      context 'when a correct format is uploaded' do
        let(:file) do
          test_file = Rack::Test::UploadedFile.new(Rails.root.join("spec", "test_data", "census_employee_import", "DCHL Employee Census.xlsx"))
          test_file.content_type = 'application/xlsx'
          test_file
        end

        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          post :bulk_employee_upload, :params => {:employer_profile_id => benefit_sponsor.profiles.first.id, :file => file}
        end

        it 'should upload sucessfully' do
          expect(response).to redirect_to(profiles_employers_employer_profile_path(benefit_sponsor.profiles.first, tab: 'employees'))
        end
      end

      context 'when a wrong format is uploaded' do
        let(:file) do
          test_file = Rack::Test::UploadedFile.new(Rails.root.join("spec", "test_data", "individual_person_payloads", "individual.xml"))
        end

        before do
          benefit_sponsorship.save!
          allow(controller).to receive(:authorize).and_return(true)
          sign_in user
          post :bulk_employee_upload, :params => {:employer_profile_id => benefit_sponsor.profiles.first.id, :file => file}
        end

        it 'should upload sucessfully' do
          expect(response).to render_template("benefit_sponsors/profiles/employers/employer_profiles/_employee_csv_upload_errors", "layouts/two_column")
        end
      end
    end


    describe "GET coverage_reports" do
      let!(:employees) {
        FactoryBot.create_list(:census_employee, 2, employer_profile: employer_profile, benefit_sponsorship: benefit_sponsorship)
      }

      before do
        benefit_sponsorship.save!
        allow(controller).to receive(:authorize).and_return(true)
        sign_in user
        get :coverage_reports, params: { employer_profile_id: benefit_sponsor.profiles.first.id, billing_date: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime("%m/%d/%Y")}
        allow(employer_profile).to receive(:active_benefit_sponsorship).and_return benefit_sponsorship
      end

      it "should render coverage_reports template" do
        assert_template "coverage_reports"
      end

      it "should return http success" do
        assert_response :success
      end
    end
  end
end
