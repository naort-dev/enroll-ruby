require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "remove_ssn")

describe RemoveSsn do
  let(:given_task_name) { "remove_ssn" }
  subject { RemoveSsn.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person ssn" do
    let(:person) { FactoryBot.create(:person, ssn:"123123123")}

    it "should change person ssn to nil" do
      ClimateControl.modify person_hbx_id: "#{person.hbx_id}" do 
        ssn=person.ssn
        expect(person.ssn).to eq ssn
        subject.migrate
        person.reload
        expect(person.ssn).to eq nil
      end
    end
  end
end