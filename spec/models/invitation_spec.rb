require "rails_helper"

describe Invitation do
  subject { Invitation.new }

  before :each do
    subject.valid?
  end

  it "should require an invitation role" do
    expect(subject).to have_errors_on(:role)
  end

  it "should require a source_id" do
    expect(subject).to have_errors_on(:source_id)
  end

  it "should require a source_kind" do
    expect(subject).to have_errors_on(:source_kind)
  end

  it "should require an invitation email" do
    expect(subject).to have_errors_on(:invitation_email)
  end

  ["employee_role", "broker_role", "employer_staff_role"].each do |role|
    it "should allow a role of #{role}" do
      record = Invitation.new(role: role)
      record.valid?
      expect(record).not_to have_errors_on(:role)
    end
  end

  ["census_employee", "broker_role", "employer_profile"].each do |source_kind|
    it "should allow a source_kind of #{source_kind}" do
      record = Invitation.new(source_kind: source_kind)
      record.valid?
      expect(record).not_to have_errors_on(:source_kind)
    end
  end
end

shared_examples "a valid invitation" do |sk, role|
    it "should be valid with a source_kind of #{sk} and a role of #{role}" do
      record = Invitation.new({role: role, source_kind: sk}.merge(valid_params))
      expect(record.valid?).to eq true
    end
end

shared_examples "an invitation with invalid source kind and role" do |sk, role|
    it "should be invalid with a source_kind of #{sk} and a role of #{role}" do
      record = Invitation.new({role: role, source_kind: sk}.merge(valid_params))
      expect(record.valid?).to eq false
      expect(record).to have_errors_on(:base)
    end
end

describe Invitation do
  def self.invite_types
    {
      "census_employee" => "employee_role",
      "broker_role" => "broker_role",
      "employer_profile" => "employer_staff_role"
    }
  end

  def self.source_kinds
    invite_types.keys
  end

  def self.role_kinds
    invite_types.values
  end
  let(:valid_params) {
    {
      :source_id => BSON::ObjectId.new,
      :invitation_email => "user@somewhere.com"
    } 
  }

  [0,1,2].each do |idx|
    include_examples "a valid invitation", source_kinds[idx], role_kinds[idx]
  end

  [[0,1],
   [0,2],
   [1,0],
   [1,2],
   [2,0],
   [2,1]].each do |idx|
    include_examples "an invitation with invalid source kind and role", source_kinds[idx.first], role_kinds[idx.last]
  end
end

describe Invitation, "starting in the initial state" do
  let(:valid_params) { {:source_id => BSON::ObjectId.new} }
  subject { Invitation.new(valid_params) }

  it "should have been 'sent'" do
    expect(subject.sent?).to eq true
  end

  it "should not have been claimed" do
    expect(subject.claimed?).to eq false
  end

  it "should be able to be claimed" do
    expect(subject.may_claim?).to eq true
  end
end

describe "A valid invitation in the sent state" do
  let(:valid_params) {
    {
      :source_id => BSON::ObjectId.new,
      :source_kind => "census_employee",
      :role => "employee_role",
      :invitation_email => "user@somewhere.com"
    } 
  }
  let(:user) { User.new }

  subject { Invitation.new(valid_params) }

  it "can be claimed by a user" do
    subject.claim_invitation!(user)
    expect(subject.user).to eq user
  end
end
