require 'rails_helper'
require 'csv'

if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
RSpec.describe IvlNotices::FinalEligibilityNoticeRenewalAqhp, :dbclean => :after_each do

  file = "#{Rails.root}/spec/test_data/notices/final_eligibility_notice_aqhp_test_data.csv"
  csv = CSV.open(file,"r",:headers =>true)
  data = csv.to_a
  year = TimeKeeper.date_of_record.year + 1
  let(:person) { FactoryBot.create(:person, :with_consumer_role, :hbx_id => "383883742")}
  let(:family) {FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:issuer_profile) { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, benefit_market_kind: :aca_individual, kind: :health, csr_variant_id: '01', issuer_profile: issuer_profile)}
  let!(:hbx_enrollment) {FactoryBot.create(:hbx_enrollment, household: family.households.first, family: family, kind: "individual", product: product, aasm_state: "auto_renewing", effective_on: Date.new(year,1,1))}
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Final Eligibility Notice for UQHP/AQHP individuals',
      :notice_template => 'notices/ivl/final_eligibility_notice_uqhp_aqhp',
      :notice_builder => 'IvlNotices::FinalEligibilityNoticeRenewalAqhp',
      :event_name => 'final_eligibility_notice_renewal_aqhp',
      :mpi_indicator => 'IVL_FRE',
      :data => data,
      :person =>  person,
      :title => "Your Final Plan Enrollment, And Remainder To Pay"})
  }
  let(:valid_params) do
    {
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template,
      :data => data,
      renewing_enrollments: [hbx_enrollment],
      active_enrollments: [],
      :person => person
    }
  end

  before :each do
    allow(person.consumer_role).to receive("person").and_return(person)
  end

  describe "New" do
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "#build" do
    before do
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_params)
      @final_eligibility_notice.build
    end

    it "returns coverage_year" do
      expect(@final_eligibility_notice.notice.coverage_year).to eq hbx_enrollment.effective_on.year.to_s
    end

    it "returns event_name" do
      expect(@final_eligibility_notice.notice.notification_type).to eq application_event.event_name
    end

    it "returns mpi_indicator" do
      expect(@final_eligibility_notice.notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end

  describe "#append_open_enrollment_data" do
    before do
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_params)
      @final_eligibility_notice.build
    end
    it "return ivl open enrollment start on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_start_on).to eq Settings.aca.individual_market.open_enrollment.start_on
    end
    it "return ivl open enrollment end on" do
      expect(@final_eligibility_notice.notice.ivl_open_enrollment_end_on).to eq Settings.aca.individual_market.open_enrollment.end_on
    end
  end

  describe "#generate_pdf_notice" do
    before do
      @final_eligibility_notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person.consumer_role, valid_params)
    end

    it "should render the final eligibility notice template" do
      expect(@final_eligibility_notice.template).to eq "notices/ivl/final_eligibility_notice_uqhp_aqhp"
    end

    it "should generate pdf" do
      @final_eligibility_notice.append_hbe
      @final_eligibility_notice.build
      file = @final_eligibility_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end

    it "should delete generated pdf" do
      @final_eligibility_notice.append_hbe
      @final_eligibility_notice.build
      file = @final_eligibility_notice.generate_pdf_notice
      @final_eligibility_notice.clear_tmp(file.path)
      expect(File.exist?(file.path)).to be false
    end
  end

  describe "for recipient, recipient_document_store", dbclean: :after_each do
    let!(:person100)          { FactoryBot.create(:person, :with_consumer_role, :with_work_email) }
    let!(:dep_family1)        { FactoryBot.create(:family, :with_primary_family_member, person: FactoryBot.create(:person, :with_consumer_role, :with_work_email)) }
    let!(:dep_family_member)  { FactoryBot.create(:family_member, family: dep_family1, person: person100) }
    let!(:family100)          { FactoryBot.create(:family, :with_primary_family_member, person: person100) }
    let(:dep_fam_primary)     { dep_family1.primary_applicant.person }

    before :each do
      valid_params.merge!({:person => person100})
      @notice = IvlNotices::FinalEligibilityNoticeRenewalAqhp.new(person100.consumer_role, valid_params)
    end

    it "should have person100 as the recipient for the enrollment notice as this person is the primary" do
      expect(@notice.recipient).to eq person100
      expect(@notice.person).to eq person100
      expect(@notice.recipient_document_store).to eq person100
      expect(@notice.to).to eq person100.work_email_or_best
    end

    it "should not pick the dep_family1's primary person" do
      expect(@notice.recipient).not_to eq dep_fam_primary
      expect(@notice.person).not_to eq dep_fam_primary
      expect(@notice.recipient_document_store).not_to eq dep_fam_primary
      expect(@notice.to).not_to eq dep_fam_primary.work_email_or_best
    end
  end
end
end
