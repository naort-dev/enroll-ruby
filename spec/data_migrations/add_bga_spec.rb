require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_benefit_group_id")
describe AddBenefitGroupId, dbclean: :after_each do
  let(:given_task_name) { "add_benefit_group_id" }
  subject { AddBenefitGroupId.new(given_task_name, double(:current_scope => nil)) }
  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "update benefit group id", dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person) }
    let(:household) {Household.new}
    let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, households: [household])}
    before(:each) do
      ENV['hbx_id'] = person.hbx_id
      allow(person).to receive(:primary_family).and_return(family)
      allow(family).to receive(:active_household).and_return(household)
      hbx = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "individual")
      hbx.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record - 30.days)
      hbx.save
    end
    
    it "should update benefit group id" do
      hbx2 = FactoryGirl.create(:hbx_enrollment, household: family.active_household, kind: "employer_sponsored", benefit_group_id: 1234)
      hbx2.hbx_enrollment_members << FactoryGirl.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record - 30.days)
      hbx2.save
      subject.migrate
      person.primary_family.active_household.hbx_enrollments.first.reload
      expect(person.primary_family.active_household.hbx_enrollments.first.benefit_group_id).to be_present
    end

    it "should not update benefit group id" do
      subject.migrate
      person.primary_family.active_household.hbx_enrollments.first.reload
      expect(person.primary_family.active_household.hbx_enrollments.first.benefit_group_id).to eq nil
    end
  end
end














# require "rails_helper"
# require 'byebug'
# require File.join(Rails.root, "app", "data_migrations", "reactivate_tax_household_with_assistance_year")

# describe ReactivateTaxHouseholdWithAssistanceYear, dbclean: :after_each do
#   let(:given_task_name) { "reactivate_tax_household_with_assistance_year" }
#   subject { ReactivateTaxHouseholdWithAssistanceYear.new(given_task_name, double(:current_scope => nil)) }
#   describe "given a task name" do
#     it "has the given task name" do
#       expect(subject.name).to eql given_task_name

#     end
#   end
#   describe "Set the effective end on to nil" do
#     let(:person) { FactoryGirl.create(:person) }
#     let(:household) {Household.new}
#     let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, households: [household])}
#     let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_73', max_aptc: 1017, csr_percent: 0.73, determined_on: TimeKeeper.date_of_record)}
#     let(:tax_household) {TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record, effective_ending_on: TimeKeeper.date_of_record+1.year, eligibility_determinations: [eligibility_determination])}
#     before(:each) do
#       ENV['primary_person_hbx_id'] = person.hbx_id
#       ENV['applicable_year'] = TimeKeeper.date_of_record.year.to_s
#       ENV['max_aptc'] = '1017'
#       ENV['csr_percent'] = '73'
#       allow(person).to receive(:primary_family).and_return(family)
#       allow(family).to receive(:active_household).and_return(household)
#       household.tax_households <<  tax_household
#     end

#     it "Set the effective end on to nil" do
#       expect(person.primary_family.active_household.tax_households.pluck(:effective_ending_on).any?).to eq(true)
#       subject.migrate
#       person.primary_family.active_household.tax_households.each {|th| th.reload}
#       expect(person.primary_family.active_household.tax_households.pluck(:effective_ending_on).any?).to eq(false)
#     end
#   end


#   describe "Should not set the effective end on to nil" do
#     let(:person) { FactoryGirl.create(:person) }
#     let(:household) {Household.new}
#     let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, households: [household])}
#     let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_73', max_aptc: 100, csr_percent: 0.73, determined_on: TimeKeeper.date_of_record)}
#     let(:tax_household) {TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record, effective_ending_on: TimeKeeper.date_of_record+1.year, eligibility_determinations: [eligibility_determination])}
#     before(:each) do
#       ENV['primary_person_hbx_id'] = person.hbx_id
#       ENV['applicable_year'] = TimeKeeper.date_of_record.year.to_s
#       ENV['max_aptc'] = '1017'
#       ENV['csr_percent'] = '73'
#       allow(person).to receive(:primary_family).and_return(family)
#       allow(family).to receive(:active_household).and_return(household)
#       household.tax_households <<  tax_household
#     end

#     it "Should not set the effective end on to nil as max_aptc do not match" do
#       expect(person.primary_family.active_household.tax_households.pluck(:effective_ending_on).any?).to eq(true)
#       subject.migrate
#       person.primary_family.active_household.tax_households.each {|th| th.reload}
#       expect(person.primary_family.active_household.tax_households.pluck(:effective_ending_on).any?).to eq(true)
#     end
#   end

#   describe "Should not set the effective end on to nil" do
#     let(:person) { FactoryGirl.create(:person) }
#     let(:household) {Household.new}
#     let(:family) { FactoryGirl.create(:family, :with_primary_family_member, person: person, households: [household])}
#     let(:eligibility_determination) {EligibilityDetermination.new(csr_eligibility_kind: 'csr_87', max_aptc: 100, csr_percent: 0.87, determined_on: TimeKeeper.date_of_record)}
#     let(:tax_household) {TaxHousehold.new(effective_starting_on: TimeKeeper.date_of_record, effective_ending_on: TimeKeeper.date_of_record+1.year, eligibility_determinations: [eligibility_determination])}
#     before(:each) do
#       ENV['primary_person_hbx_id'] = person.hbx_id
#       ENV['applicable_year'] = TimeKeeper.date_of_record.year.to_s
#       ENV['max_aptc'] = '1017'
#       ENV['csr_percent'] = '73'
#       allow(person).to receive(:primary_family).and_return(family)
#       allow(family).to receive(:active_household).and_return(household)
#       household.tax_households <<  tax_household
#     end

#     it "Should not set the effective end on to nil as csr_eligibility_kind do not match" do
#       expect(person.primary_family.active_household.tax_households.pluck(:effective_ending_on).any?).to eq(true)
#       subject.migrate
#       person.primary_family.active_household.tax_households.each {|th| th.reload}
#       expect(person.primary_family.active_household.tax_households.pluck(:effective_ending_on).any?).to eq(true)
#     end
#   end
# end
