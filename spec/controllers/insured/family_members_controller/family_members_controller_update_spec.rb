# frozen_string_literal: true

require "rails_helper"

RSpec.describe Insured::FamilyMembersController do
  describe "PUT update, for an IVL market dependent with a consumer role" do
    let(:dependent_id) { "SOME DEPENDENT ID" }
    let(:person) { instance_double(Person) }
    let(:user) { instance_double("User", :primary_family => family, :person => person) }
    let(:dependent) do
      instance_double(
        Forms::FamilyMember,
        addresses: [],
        same_with_primary: 'true',
        family_id: family_id,
        family_member: family_member
      )
    end
    let(:immediate_family_coverage_household) { double(coverage_household_members: []) }
    let(:extended_family_coverage_household) { double(coverage_household_members: []) }
    let(:active_household) do
      double(
        immediate_family_coverage_household: immediate_family_coverage_household,
        extended_family_coverage_household: extended_family_coverage_household
      )
    end
    let(:family) { instance_double(Family, id: family_id, active_family_members: [], active_household: active_household) }
    let(:family_id) { "SOME FAMILY ID" }
    let(:family_member) do
      instance_double(
        FamilyMember,
        person: dependent_person,
        family: family
      )
    end
    let(:dependent_person) do
      instance_double(
        Person,
        consumer_role: consumer_role,
        is_resident_role_active?: false
      )
    end
    let(:consumer_role) do
      instance_double(
        ConsumerRole,
        person: double(is_homeless: false, is_temporarily_out_of_state: false),
        local_residency_validation: nil,
        residency_determined_at: nil
      )
    end

    let(:dependent_controller_parameters) do
      ActionController::Parameters.new(dependent_update_properties).permit!
    end

    before(:each) do
      sign_in(user)
      allow(person).to receive(:agent?).and_return(false)
      allow(Forms::FamilyMember).to receive(:find).with(dependent_id).and_return(dependent)
      allow(Family).to receive(:find).with(family_id).and_return(family)
      allow(dependent).to receive(:update_attributes).with(dependent_controller_parameters).and_return(true)
      allow(consumer_role).to receive(:sensitive_information_changed?).with(dependent_update_properties).and_return(false)
      allow(consumer_role).to receive(:check_for_critical_changes).with(family, info_changed: false, is_homeless: nil, is_temporarily_out_of_state: nil, dc_status: false)
    end

    describe "when the value for 'is_applying_coverage' is provided" do
      let(:is_applying_coverage_value) { "false" }
      let(:dependent_update_properties) do
        { "first_name" => "Dependent First Name", "same_with_primary" => "true", "is_applying_coverage" => is_applying_coverage_value }
      end


      it "updates the 'is_applying_coverage' value for the dependent" do
        expect(consumer_role).to receive(:update_attribute).with(:is_applying_coverage, is_applying_coverage_value).and_return(true)
        put :update, params: {id: dependent_id, dependent: dependent_update_properties}
      end
    end

    describe "when the value for 'is_applying_coverage' is NOT provided" do
      let(:dependent_update_properties) do
        { "first_name" => "Dependent First Name", "same_with_primary" => "true" }
      end

      it "does not change the 'is_applying_coverage' value for the dependent" do
        expect(consumer_role).not_to receive(:update_attribute)
        put :update, params: {id: dependent_id, dependent: dependent_update_properties}
      end
    end
  end
end