require 'rails_helper'

RSpec.describe Insured::FamilyMembersController do
  let(:family) { double }
  let(:user) { instance_double("User", :primary_family => family, :person => person) }
  let(:person) { double(:employee_roles => [], :primary_family => family) }
  let(:employee_role_id) { "2343" }
  let(:qle) { FactoryGirl.create(:qualifying_life_event_kind) }
  let(:fm) { FactoryGirl.build(:family, :with_primary_family_member) }
  let(:employee_role){ double("EmployeeRole", id: double("id")) }
  describe "GET index" do
    context 'normal' do
      before(:each) do
        allow(person).to receive(:employee_role).and_return(employee_role)
        allow(user).to receive(:person).and_return(person)
        allow(employee_role).to receive(:save!).and_return(true)
        sign_in(user)
        get :index, :employee_role_id => employee_role_id
      end

      it "renders the 'index' template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("index")
      end

      it "assigns the person" do
        expect(assigns(:person)).to eq person
      end

      it "assigns the family" do
        expect(assigns(:family)).to eq family
      end
    end

    it "with qle_id" do
      allow(person).to receive(:employee_role).and_return(employee_role)
      allow(person).to receive(:primary_family).and_return(fm)
      allow(employee_role).to receive(:save!).and_return(true)
      sign_in user
      expect{
        get :index, employee_role_id: employee_role_id, qle_id: qle.id, effective_on_kind: 'date_of_event', qle_date: '10/10/2015'
      }.to change(fm.special_enrollment_periods, :count).by(1)
    end
  end

  describe "GET show" do
    let(:dependent) { double("Dependent") }
    let(:family_member) {double("FamilyMember", id: double("id"))}

    before(:each) do
      allow(Forms::FamilyMember).to receive(:find).and_return(dependent)
      sign_in(user)
      get :show, :id => family_member.id
    end

    it "should render show templage" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("show")
    end
  end

  describe "GET new" do
    let(:family_id) { "addbedddedtotallyafamiyid" }
    let(:dependent) { double }

    before(:each) do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:new).with({:family_id => family_id}).and_return(dependent)
      get :new, :family_id => family_id
    end

    it "renders the 'new' template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("new")
    end

    it "assigns the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end
  end

  describe "POST create" do
    let(:address) { double }
    let(:dependent) { double(addresses: address, family_member: true, same_with_primary: true) }
    let(:dependent_properties) { { :family_id => "saldjfalkdjf"} }
    let(:save_result) { false }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:new).with(dependent_properties).and_return(dependent)
      allow(dependent).to receive(:save).and_return(save_result)
      allow(dependent).to receive(:address=)
      post :create, :dependent => dependent_properties
    end

    describe "with an invalid dependent" do
      it "should assign the dependent" do
        expect(assigns(:dependent)).to eq dependent
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end

    describe "with a valid dependent" do
      let(:save_result) { true }

      it "should assign the dependent" do
        expect(assigns(:dependent)).to eq dependent
      end

      it "should assign the created" do
        expect(assigns(:created)).to eq true
      end

      it "should render the show template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end
    end

    describe "when update_vlp_documents failed" do
      before :each do
        allow(controller).to receive(:update_vlp_documents).and_return false
      end

      it "should render the new template" do
        expect(response).to have_http_status(:success)
        expect(response).to render_template("new")
      end
    end
  end

  describe "DELETE destroy" do
    let(:dependent) { double }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
    end

    it "should destroy the dependent" do
      expect(dependent).to receive(:destroy!)
      delete :destroy, :id => dependent_id
    end

    it "should render the index template" do
      allow(dependent).to receive(:destroy!)
      delete :destroy, :id => dependent_id
      expect(response).to have_http_status(:success)
      expect(response).to render_template("index")
    end
  end

  describe "GET edit" do
    let(:dependent) { double(family_member: double) }
    let(:dependent_id) { "234dlfjadsklfj" }

    before :each do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      get :edit, :id => dependent_id
    end

    it "should assign the dependent" do
      expect(assigns(:dependent)).to eq dependent
    end

    it "should render the edit template" do
      expect(response).to have_http_status(:success)
      expect(response).to render_template("edit")
    end
  end

  describe "PUT update" do
    let(:address) { double }
    let(:dependent) { double(addresses: address, family_member: true, same_with_primary: true) }
    let(:dependent_id) { "234dlfjadsklfj" }
    let(:dependent_properties) { { "first_name" => "lkjdfkajdf" } }
    let(:update_result) { false }

    before(:each) do
      sign_in(user)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(dependent).to receive(:update_attributes).with(dependent_properties).and_return(update_result)
      allow(address).to receive(:is_a?).and_return(true)
      allow(dependent).to receive(:same_with_primary=)
      allow(dependent).to receive(:addresses=) 
    end

    describe "with an invalid dependent" do
      it "should render the edit template" do
        expect(Address).to receive(:new)
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end 
    end

    describe "with a valid dependent" do
      let(:update_result) { true }
      it "should render the show template" do
        allow(controller).to receive(:update_vlp_documents).and_return(true)
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(response).to have_http_status(:success)
        expect(response).to render_template("show")
      end 

      it "should render the edit template when update_vlp_documents failure" do
        allow(controller).to receive(:update_vlp_documents).and_return(false)
        put :update, :id => dependent_id, :dependent => dependent_properties
        expect(response).to have_http_status(:success)
        expect(response).to render_template("edit")
      end 
    end 
  end
end
