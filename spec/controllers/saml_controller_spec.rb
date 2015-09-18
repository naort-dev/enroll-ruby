require 'rails_helper'

RSpec.describe SamlController do

  describe "POST login" do
    let(:user) { FactoryGirl.create(:user, last_portal_visited: family_account_path)}
    invalid_xml = File.read("spec/saml/invalid_saml_response.xml")


    before(:each) do

    end

    context "with devise session active" do
      it "should sign out current user" do
        sign_in user
        expect(subject).to receive(:sign_out).with(user)
        post :login, :SAMLResponse => invalid_xml
      end
    end

    context "with invalid saml response" do

      it "should render a 403" do
        expect(subject).to receive(:log) do |arg1, arg2|
          expect(arg1).to match(/ERROR: SAMLResponse assertion errors/)
          expect(arg2).to eq(:severity => 'error')
        end
        post :login, :SAMLResponse => invalid_xml
        expect(response).to render_template(:file => "#{Rails.root}/public/403.html")
        expect(response).to have_http_status(403)
      end
    end

    # context "with valid saml response" do

    #   sample_xml = File.read("spec/saml/invalid_saml_response.xml")

    #   describe "with an existing user" do
    #     it "should redirect back to their last portal" do
    #       allow(User).to receive(:where).and_return([user])
    #       post :login, :SAMLResponse => sample_xml
    #       expect(response).to redirect_to(user.last_portal_visited)
    #       puts user.last_portal_visited
    #     end
    #   end

    #   describe "with a new user" do
    #     it "should claim the invitation" do
    #       allow(User).to receive(:where).and_return([])
    #       post :login, :SAMLResponse => sample_xml
    #       expect(response).to redirect_to(search_insured_consumer_role_index_path)
    #     end
    #   end

    # end



  end
end
