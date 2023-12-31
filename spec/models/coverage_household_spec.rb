require 'rails_helper'

describe CoverageHousehold, type: :model do
  context "family_members" do
    let!(:family) {  FactoryBot.create(:family, :with_primary_family_member)}
    let!(:family_member2) { FactoryBot.create(:family_member, family: family, is_active: false)}
    let(:coverage_household) { family.active_household.immediate_family_coverage_household }

    it "should return blank array" do
      allow(coverage_household).to receive(:family).and_return(nil)
      expect(coverage_household.family_members).to eq []
    end

    it "should return active_family_members" do
      expect(coverage_household.family_members).to eq [family.primary_applicant]
    end
  end

  context "valid_coverage_household_members" do
    let(:person) {FactoryBot.create(:person)}
    let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let(:family_member) {FactoryBot.create(:family_member, family: family)}
    let(:coverage_household) { family.latest_household.coverage_households.first }
    let(:coverage_household_member1) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }
    let(:coverage_household_member2) { CoverageHouseholdMember.new(:family_member_id => nil) }
    let(:coverage_household_member3) { CoverageHouseholdMember.new(:family_member_id => family_member.id) }

    before do
      coverage_household.coverage_household_members << [coverage_household_member1, coverage_household_member2, coverage_household_member3]
      coverage_household.save
    end

    it "should not include inactive valid_coverage_household_members " do
      family_member.update_attributes(is_active: false)
      expect(coverage_household.valid_coverage_household_members).not_to include(coverage_household_member3)
    end

    it "should include valid_coverage_household_members " do
      expect(coverage_household.valid_coverage_household_members).to include(coverage_household_member1)
      expect(coverage_household.valid_coverage_household_members).not_to include(coverage_household_member2)
    end
  end
end

describe CoverageHousehold, "when informed that eligiblity has changed for an individual" do
  let(:mock_person) { double }
  let(:mock_consumer_role) { double(person: mock_person) }
  let(:matching_coverage_household) { instance_double("CoverageHousehold") }
  let(:matching_hbx_enrollment) { instance_double("HbxEnrollment") }
  let(:hbxs) { [matching_hbx_enrollment] }
  let(:mock_household) { instance_double("Household", :coverage_households => [matching_coverage_household], hbx_enrollments: hbxs) }
  let(:mock_family) { instance_double("Family", :households => [mock_household]) }

  before :each do
    allow(Family).to receive(:find_all_by_person).with(mock_person).and_return([mock_family])
  end

  it "should locate and notify each coverage household containing that individual" do
    expect(matching_coverage_household).to receive(:evaluate_individual_market_eligiblity)
    expect(matching_hbx_enrollment).to receive(:evaluate_individual_market_eligiblity)
    CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
  end

  describe "and that individual exists on individual market policies" do
    let(:matching_coverage_household) { CoverageHousehold.new }
    let(:mock_ruleset) { instance_double(::RuleSet::CoverageHousehold::IndividualMarketVerification, :applicable? => true, :determine_next_state => recommended_event) }

    before :each do
      allow(::RuleSet::CoverageHousehold::IndividualMarketVerification).to receive(:new).with(matching_coverage_household).and_return(mock_ruleset)
      allow(matching_coverage_household).to receive(:aasm_state).and_return("enrolled")
      allow(matching_hbx_enrollment).to receive(:evaluate_individual_market_eligiblity).and_return(true)
    end

    describe "with a ruleset recommending contingent status" do
      let(:recommended_event) { :move_to_contingent! }
      it "should update it's state to match the state provided by the ruleset" do
        expect(matching_coverage_household).to receive(recommended_event)
        CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
      end
    end

    describe "with a ruleset recommending pending status" do
      let(:recommended_event) { :move_to_pending! }
      it "should update it's state to match the state provided by the ruleset" do
        expect(matching_coverage_household).to receive(recommended_event)
        CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
      end
    end

    describe "with a ruleset recommending enrolled status" do
      let(:recommended_event) { :move_to_enrolled! }
      it "should update it's state to match the state provided by the ruleset" do
        expect(matching_coverage_household).to receive(recommended_event)
        CoverageHousehold.update_individual_eligibilities_for(mock_consumer_role)
      end
    end
  end
  describe "coverage household with invalid aasm state" do
    let(:person) {FactoryBot.create(:person)}
    let(:primary_family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:coverage_household) { primary_family.active_household.coverage_households.first}
    let(:enrollment){ FactoryBot.create(:hbx_enrollment, coverage_household_id: coverage_household.id, family: primary_family, household: primary_family.active_household) }

    before do
      coverage_household.active_individual_enrollments << enrollment
      coverage_household.save!
    end

    it "should not throw an exception while in applicant state and there are present enrollments" do
      coverage_household.reload
      expect(coverage_household.evaluate_individual_market_eligiblity).to be(nil)
    end
  end
end
