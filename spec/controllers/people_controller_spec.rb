require 'rails_helper'

RSpec.describe PeopleController, dbclean: :after_each do
  let(:census_employee_id) { "abcdefg" }
  let(:user) { FactoryBot.build(:user) }
  let(:email) {FactoryBot.build(:email)}

  let(:consumer_role){FactoryBot.build(:consumer_role)}

  let(:census_employee){FactoryBot.build(:census_employee)}
  let(:employee_role){FactoryBot.build(:employee_role, :census_employee => census_employee)}
  let(:person) { FactoryBot.create(:person, :with_employee_role) }


  let(:vlp_document){FactoryBot.build(:vlp_document)}

  it "GET new" do
    sign_in(user)
    get :new
    expect(response).to have_http_status(:success)
  end

  describe "POST create" do
    context "with valid attributes" do 
      it 'should add a new person' do 
        expect { post :create, params: {person: FactoryBot.attributes_for(:person)} }.to change(Person,:count).by(0)
      end
    end

    context "with invalid attributes"  do
      it 'should not add a new person' do  
        expect { post :create, params: {person: FactoryBot.attributes_for(:person,:with_bad_mailing_address)} }.to_not change(Person,:count)
      end
    end
  end

  describe "POST update" do
    let(:vlp_documents_attributes) { {"1" => vlp_document.attributes.to_hash}}
    let(:consumer_role_attributes) { consumer_role.attributes.to_hash}
    let(:person_attributes) { person.attributes.to_hash}
    let(:employee_roles) { person.employee_roles }
    let(:census_employee_id) {employee_roles[0].census_employee_id}

    let(:email_attributes) { {"0"=>{"kind"=>"home", "address"=>"test@example.com"}}}
    let(:addresses_attributes) { {"0"=>{"kind"=>"home", "address_1"=>"address1_a", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211", "id"=> person.addresses[0].id.to_s},
        "1"=>{"kind"=>"mailing", "address_1"=>"address1_b", "address_2"=>"", "city"=>"city1", "state"=>"DC", "zip"=>"22211", "id"=> person.addresses[1].id.to_s} } }

    before :each do
      allow(Person).to receive(:find).and_return(person)
      allow(Person).to receive(:where).and_return(Person)
      allow(Person).to receive(:first).and_return(person)
      # allow(controller).to receive(:sanitize_person_params).and_return(true)
      allow(person).to receive(:consumer_role).and_return(consumer_role)
      allow(consumer_role).to receive(:check_for_critical_changes)
      allow(person).to receive(:update_attributes).and_return(true)
      allow(person).to receive(:has_active_consumer_role?).and_return(false)
      person_attributes[:addresses_attributes] = addresses_attributes
      sign_in user
      post :update, params: {id: person.id, person: person_attributes}
    end


    context "to verify if addresses are updated?" do

      it "should not create new address instances on update" do
        expect(person.addresses.count).to eq 2
      end

      it "should not empty the person's addresses on update" do
        expect(person.addresses).not_to eq []
      end
    end

    context "when individual" do

      before do
        request.headers.merge!(referer: "insured/families/personal")
        allow(person).to receive(:has_active_consumer_role?).and_return(true)
      end
      it "update person" do
        allow(consumer_role).to receive(:find_document).and_return(vlp_document)
        allow(vlp_document).to receive(:save).and_return(true)
        consumer_role_attributes[:vlp_documents_attributes] = vlp_documents_attributes
        person_attributes[:consumer_role_attributes] = consumer_role_attributes
        # binding.pry
        post :update,  params: {id: person.id, person: person_attributes}
        expect(response).to redirect_to(personal_insured_families_path)
        expect(assigns(:person)).not_to be_nil
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end

      it "should update is_applying_coverage" do
        allow(person).to receive(:update_attributes).and_return(true)
        person_attributes.merge!({"is_applying_coverage" => "false"})

        post :update, params: {id: person.id, person: person_attributes}
        expect(assigns(:person).consumer_role.is_applying_coverage).to eq false
      end
    end

    context "when employee" do
      it "when employee" do
        person_attributes[:emails_attributes] = email_attributes
        allow(controller).to receive(:get_census_employee).and_return(census_employee)
        allow(person).to receive(:update_attributes).and_return(true)

        post :update, params: {id: person.id, person: person_attributes}
        expect(response).to redirect_to(family_account_path)
        expect(flash[:notice]).to eq 'Person was successfully updated.'
      end
    end
  end
end
