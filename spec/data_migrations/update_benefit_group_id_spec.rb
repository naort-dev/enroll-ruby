require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "update_benefit_group_id")
describe UpdateBenefitGroupId, dbclean: :after_each do
  let(:given_task_name) { "update_benefit_group_id" }
  subject { UpdateBenefitGroupId.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update benefit group id", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person) }
    let(:household) {Household.new}
    let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, households: [household])}
    let(:new_benefit_group) { FactoryBot.create(:benefit_group) }
    let(:hbx2) {FactoryBot.create(:hbx_enrollment, family: family, household: family.active_household, kind: "employer_sponsored")}
    
    around do |example|
      ClimateControl.modify benefit_group_id: new_benefit_group.id, enrollment_hbx_id: hbx2.hbx_id do
        example.run
      end
    end

    before(:each) do
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:active_household).and_return(household)     
      hbx2.hbx_enrollment_members << FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record - 30.days)
      hbx2.save!
    end
    
    it "should update benefit group id" do
      hbx2.update_attributes!(benefit_group_id: nil)
      expect(hbx2.benefit_group_id).to eq(nil)
      subject.migrate
      hbx2.reload
      expect(hbx2.benefit_group_id).to eq(new_benefit_group.id)
    end
  end
end
