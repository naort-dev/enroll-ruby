require "rails_helper"

RSpec.describe "broker_agencies/profiles/_employers.html.erb", :dbclean => :after_each do
  let(:organization) { FactoryBot.create(:organization) }
  let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, organization: organization) }
  let(:employer_profile) { FactoryBot.create(:employer_profile, organization: organization) }
  before :each do
    assign :broker_agency_profile, broker_agency_profile
    assign :employer_profiles, [employer_profile]
    assign :page_alphabets, ['a']
    assign :general_agency_profiles, []
    allow(view).to receive(:controller_name).and_return 'profiles'
  end

  describe 'with modify permissions' do
    context "General Agency can be enabled or disabled via resource registry" do
      context "when enabled" do
        before :each do
          EnrollRegistry[:general_agency].feature.stub(:is_enabled).and_return(true)
          render template: "broker_agencies/profiles/_employers.html.erb"
        end
        it "should have general agency" do
          expect(rendered).to match(/General Agencies/)
        end

        it "should have button for ga assign" do
          expect(rendered).to have_selector('#assign_general_agency')
        end

        it "should not have a blocked button for ga assign" do
          expect(rendered).not_to have_selector('.blocking #assign_general_agency')
        end
      end
      context "when disabled" do
        before do
          EnrollRegistry[:general_agency].feature.stub(:is_enabled).and_return(false)
          render template: "broker_agencies/profiles/_employers.html.erb"
        end
        it "should not have general agency" do
          expect(rendered).to_not match(/General Agencies/)
        end

        it "should not have button for ga assign" do
          expect(rendered).to_not have_selector('#assign_general_agency')
        end
      end
    end
  end

  describe 'without modify permissions ' do
    before :each do
      render template: "broker_agencies/profiles/_employers.html.erb"
    end

    context "when GA is enabled", :if => EnrollRegistry.feature_enabled?(:general_agency)  do
      it "should have general agency" do
        expect(rendered).to match(/General Agencies/)
      end
    end

    context "when GA is disabled", :unless => EnrollRegistry.feature_enabled?(:general_agency) do
      it "should not have general agency" do
        expect(rendered).not_to match(/General Agencies/)
      end
      it "should not have general agency in table" do
        expect(rendered).not_to match(/General Agency/)
      end
    end
  end
end
