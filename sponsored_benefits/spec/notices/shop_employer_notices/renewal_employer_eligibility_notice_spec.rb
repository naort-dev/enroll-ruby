require 'rails_helper'

RSpec.describe ShopEmployerNotices::RenewalEmployerEligibilityNotice do
  let(:employer_profile){ create :employer_profile}
  let(:person){ create :person}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'PlanYear Renewal',
                            :notice_template => 'notices/shop_employer_notices/3a_3b_employer_plan_year_renewal',
                            :notice_builder => 'ShopEmployerNotices::RenewalEmployerEligibilityNotice',
                            :mpi_indicator => 'MPI_SHOPRA',
                            :event_name => 'planyear_renewal_3a',
                            :title => "Plan Offerings Finalized"})
                          }
    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

  describe "New" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      allow(employer_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::RenewalEmployerEligibilityNotice.new(employer_profile, valid_parmas)
    end
    it "should build notice with all necessory info" do
      @employer_notice.build
      expect(@employer_notice.notice.primary_fullname).to eq person.full_name.titleize
      expect(@employer_notice.notice.employer_name).to eq employer_profile.organization.legal_name
      expect(@employer_notice.notice.primary_identifier).to eq employer_profile.hbx_id
    end
  end

end