require 'rails_helper'

RSpec.describe 'BenefitSponsors::ModelEvents::BrokerHiredNoticeToBroker', dbclean: :around_each  do
  let(:notice_event) { "broker_hired_notice_to_broker" }
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}

  let!(:person) { create :person }
  let(:user)    { FactoryGirl.create(:user, :person => person)}
  let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:organization_with_hbx_profile)  { site.owner_organization }
  let!(:organization)     { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
  let!(:model_instance)    { organization.employer_profile }
  let!(:benefit_sponsorship)    { model_instance.add_benefit_sponsorship }

  let!(:person1) { FactoryGirl.create(:person) }
  let!(:broker_agency_organization1) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_broker_agency_profile, legal_name: 'First Legal Name', site: site) }
  let!(:broker_agency_profile) { broker_agency_organization1.broker_agency_profile}
  let!(:broker_agency_account) { create :benefit_sponsors_accounts_broker_agency_account, broker_agency_profile: broker_agency_profile, benefit_sponsorship: benefit_sponsorship }
  let!(:broker_role) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person1) }

  before do
    broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
  end
 
  describe "NoticeTrigger" do
    context "when ER successfully hires a broker" do
      subject { BenefitSponsors::Observers::BrokerAgencyAccountObserver.new }
      it "should trigger notice event" do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq "acapi.info.events.broker.broker_hired_notice_to_broker"
          expect(payload[:event_object_kind]).to eq 'BenefitSponsors::Organizations::AcaShopCcaEmployerProfile'
          expect(payload[:event_object_id]).to eq model_instance.id.to_s
        end
        subject.notifier.deliver(recipient: broker_role, event_object: model_instance, notice_event: notice_event)
      end
    end
  end

  describe "NoticeBuilder" do

    let(:data_elements) {
      [
          "broker_profile.notice_date",
          "broker_profile.employer_name",
          "broker_profile.first_name",
          "broker_profile.last_name",
          "broker_profile.assignment_date",
          "broker_profile.broker_agency_name",
          "broker_profile.employer_poc_firstname",
          "broker_profile.employer_poc_lastname"
      ]
    }

    let(:recipient) { "Notifier::MergeDataModels::BrokerProfile" }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }
    let(:payload)   { {
        "event_object_kind" => "BenefitSponsors::Organizations::AcaShopCcaEmployerProfile",
        "event_object_id" => model_instance.id
    } }
    let(:subject) { Notifier::NoticeKind.new(template: template, recipient: recipient) }
    let(:merge_model) { subject.construct_notice_object }

    before do
      allow(subject).to receive(:resource).and_return(broker_agency_profile.primary_broker_role)
      allow(subject).to receive(:payload).and_return(payload)
      person.employer_staff_roles.create! benefit_sponsor_employer_profile_id: model_instance.id
    end

    it "should return merge model" do
      expect(merge_model).to be_a(recipient.constantize)
    end

    it "should return notice date" do
      expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    it "should return employer name" do
      expect(merge_model.employer_name).to eq model_instance.legal_name
    end

    it "should return broker first name " do
      expect(merge_model.first_name).to eq broker_role.person.first_name
    end

    it "should return broker last name " do
      expect(merge_model.last_name).to eq broker_role.person.last_name
    end

    it "should return broker assignment date" do
      expect(merge_model.assignment_date).to eq broker_agency_account.start_on.strftime('%m/%d/%Y')
    end

    it "should return employer poc first name" do
      expect(merge_model.employer_poc_firstname).to eq model_instance.staff_roles.first.first_name
    end

    it "should return employer poc last name" do
      expect(merge_model.employer_poc_lastname).to eq model_instance.staff_roles.first.last_name
    end

    it "should return broker agency name " do
      expect(merge_model.broker_agency_name).to eq broker_agency_profile.legal_name
    end

  end
end
