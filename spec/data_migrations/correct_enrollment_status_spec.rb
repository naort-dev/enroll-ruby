require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "correct_enrollment_status")

#1. Move enrollment to contingent state if any of hbx_enrollment_members has outstanding status
#2. move to pending if any has pending state
#3. move to coverage selected if all hbx_enrollment_members fully_verified

describe CorrectEnrollmentStatus, dbclean: :after_each do
  subject { CorrectEnrollmentStatus.new("correct_enrollment_state", double(:current_scope => nil)) }
  verification_states = %w(unverified ssa_pending dhs_pending verification_outstanding fully_verified verification_period_ended)
  verification_states.each do |state|
    obj=(state+"_person").to_sym
    let(obj) {
      person = FactoryBot.create(:person, :with_active_consumer_role, :with_consumer_role)
      person.consumer_role.aasm_state = state
      person
    }

    family_member = (state+"_family_member").to_sym
    let(family_member) { FamilyMember.new(person: eval(obj.to_s)) }
    hbx_enrollment_member = (state+"_enrollment_member").to_sym
    let(hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: eval(family_member.to_s) ) }
  end

  let(:family) { FactoryBot.create(:family, :with_primary_family_member, person: verification_outstanding_person) }
  let(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01') }
  let(:hbx_enrollment_member){ FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.first.id, eligibility_date: (TimeKeeper.date_of_record).beginning_of_month) }
  let(:enrollment) {
    FactoryBot.create(:hbx_enrollment,
                      product: product,
                      hbx_enrollment_members: [ hbx_enrollment_member ],
                      household: family.active_household,
                      coverage_kind: "health",
                      effective_on: TimeKeeper.date_of_record.next_month.beginning_of_month,
                      enrollment_kind: "open_enrollment",
                      kind: "individual",
                      submitted_at: TimeKeeper.date_of_record,
                      aasm_state: 'shopping')
  }

  context "assigns proper states for people" do
    verification_states.each do |status|
      it "#{status}_person has #{status} aasm_state" do
        expect(eval("#{status}_person").consumer_role.aasm_state).to eq status
      end
    end
  end

  describe "verification successful" do
    before :each do
      enrollment.aasm_state = "unverified"
      enrollment.save!
      allow(subject).to receive(:get_families).and_return([family])
      allow(subject).to receive(:get_enrollments).and_return([enrollment])
      allow(subject).to receive(:get_members).and_return([fully_verified_person.consumer_role])
      subject.migrate
    end
    context "enrollment with fully verified member" do
      it "moves hbx_enrollment to coverage_selected state" do
        expect(enrollment.aasm_state).to eq "coverage_selected"
      end
    end

  end

  describe "verification incomplete" do
    before :each do
      allow(subject).to receive(:get_families).and_return([family])
      allow(subject).to receive(:get_enrollments).and_return([enrollment])
      enrollment.update_attributes(aasm_state: "coverage_selected")
    end
    context "enrollment with outstanding member" do
      it "moves hbx_enrollment to coverage select state and set is_any_enrollment_member_outstanding to true" do
        allow(subject).to receive(:get_members).and_return([verification_outstanding_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "coverage_selected"
        expect(enrollment.is_any_enrollment_member_outstanding).to eq true
      end
    end

    context "enrollment with verification_period_ended member" do
      it "moves hbx_enrollment to coverage select state and set is_any_enrollment_member_outstanding to true" do
        allow(subject).to receive(:get_members).and_return([verification_period_ended_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "coverage_selected"
        expect(enrollment.is_any_enrollment_member_outstanding).to eq true
      end
    end

    context "enrollment with pending member" do
      it "moves hbx_enrollment to unverified state" do
        allow(subject).to receive(:get_members).and_return([ssa_pending_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "unverified"
      end
    end

    context "enrollment with mixed and outstanding members" do
      it "moves hbx_enrollment to coverage select state and set is_any_enrollment_member_outstanding to true" do
        allow(subject).to receive(:get_members).and_return([verification_outstanding_person.consumer_role, fully_verified_person.consumer_role, ssa_pending_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "coverage_selected"
        expect(enrollment.is_any_enrollment_member_outstanding).to eq true
      end
    end

    context "enrollment with mixed, NO outstanding, with pending members" do
      it "moves hbx_enrollment to unverified state" do
        allow(subject).to receive(:get_members).and_return([ssa_pending_person.consumer_role, fully_verified_person.consumer_role, dhs_pending_person.consumer_role])
        subject.migrate
        expect(enrollment.aasm_state).to eq "unverified"
      end
    end
  end
end
