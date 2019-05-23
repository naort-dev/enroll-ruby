require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "change_person_phone_number")

describe ChangePersonPhoneNumber do

  let(:given_task_name) { "change_person_phone_number" }
  subject { ChangePersonPhoneNumber.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end
  describe "changing the phone number of a given person with country code ", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person) }
    let(:phone) {FactoryGril.create(:phone,:for_testing, person:person)}
    around do |example|
      ClimateControl.modify hbx_id: person.hbx_id,
                            phone_kind: 'home',
                            full_phone_number: "20212345678",
                            country_code: '1' do
        example.run
      end
    end
    it "should have the correct country code" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.country_code).to eq "1"
    end
    it "should have the correct extension" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.extension).to eq "8"
    end
    it "should have the correct area code" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.area_code).to eq "202"
    end
    it "should have the correct number" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.number).to eq "1234567"
    end
  end
  describe "changing the phone number of a given person with no country code ", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person) }
    let(:phone) {FactoryGril.create(:phone,:for_testing, person:person)}
    around do |example|
      ClimateControl.modify hbx_id: person.hbx_id,
                            phone_kind: 'home',
                            full_phone_number: "20212345678",
                            country_code: '' do
        example.run
      end
    end

    it "should have the correct extension" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.extension).to eq "8"
    end
    it "should have the correct country code" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.country_code).to eq ""
    end
    it "should have the correct area code" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.area_code).to eq "202"
    end
    it "should have the correct number" do
      subject.migrate
      person.reload
      phone = person.phones.first
      expect(phone.number).to eq "1234567"
    end
  end
end
