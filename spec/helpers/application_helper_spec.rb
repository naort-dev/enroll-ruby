require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do
  describe "#dob_in_words" do
    it "returns date of birth in words for < 1 year" do
      expect(helper.dob_in_words(0, "20/06/2015".to_date)).to eq time_ago_in_words("20/06/2015".to_date)
      expect(helper.dob_in_words(0, "20/07/2015".to_date)).to eq time_ago_in_words("20/07/2015".to_date)
      expect(helper.dob_in_words(0, "20/07/2014".to_date)).to eq time_ago_in_words("20/07/2014".to_date)
    end
  end

  describe "#enrollment_progress_bar" do
    let(:employer_profile){FactoryGirl.create(:employer_profile)}
    let(:plan_year){FactoryGirl.create(:plan_year, employer_profile: employer_profile)}

    it "display progress bar" do
      expect(helper.enrollment_progress_bar(plan_year, 1, minimum: false)).to include('<div class="progress-wrapper">')
    end
  end

  describe "#fein helper methods" do
    it "returns fein with masked fein" do
      expect(helper.number_to_obscured_fein("111098222")).to eq "**-***8222"
    end

    it "returns formatted fein" do
      expect(helper.number_to_fein("111098222")).to eq "11-1098222"
    end
  end

  describe "date_col_name_for_broker_roaster" do
    context "for applicants controller" do
      before do
        expect(helper).to receive(:controller_name).and_return("applicants")
      end
      it "should return accepted date" do
        assign(:status, "active")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Accepted Date'
      end
      it "should return terminated date" do
        assign(:status, "broker_agency_terminated")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Terminated Date'
      end
      it "should return declined_date" do
        assign(:status, "broker_agency_declined")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Declined Date'
      end
    end
    context "for other than applicants controller" do
      before do
        expect(helper).to receive(:controller_name).and_return("test")
      end
      it "should return certified" do
        assign(:status, "certified")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Certified Date'
      end
      it "should return decertified" do
        assign(:status, "decertified")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Decertified Date'
      end
      it "should return denied" do
        assign(:status, "denied")
        expect(helper.date_col_name_for_broker_roaster).to eq 'Denied Date'
      end
    end
  end

  describe "relationship_options" do
    let(:dependent){ double("FamilyMember") }

    context "consumer_portal" do
      it "should return correct options for consumer portal" do
        expect(helper.relationship_options(dependent, "consumer_role_id")).to match(/Domestic Partner/mi)
        expect(helper.relationship_options(dependent, "consumer_role_id")).to match(/other tax dependent/mi)
      end
    end

    context "employee portal" do
      it "should not match options that are in consumer portal" do
        expect(helper.relationship_options(dependent, "")).not_to match(/Domestic Partner/mi)
        expect(helper.relationship_options(dependent, "")).not_to match(/other tax dependent/mi)
      end
    end

  end

  describe "#is_readonly" do
    # let(:user){FactoryGirl.create(:user)}
    let(:user){ double("User")}
    let(:census_employee){ double("CensusEmployee") }
    before do
      expect(helper).to receive(:current_user).and_return(user)
    end
    it "census_employee can edit if it is new record" do
      expect(user).to receive(:roles).and_return(["employee"])
      expect(helper.is_readonly(CensusEmployee.new)).to eq false # readonly -> false
    end
    it "census_employee cannot edit if linked to an employer" do
      expect(user).to receive(:roles).and_return(["employee"])
      expect(census_employee).to receive(:employee_role_linked?).and_return(true)
      expect(helper.is_readonly(census_employee)).to eq true # readonly -> true
    end
    it "hbx admin edit " do
      expect(user).to receive(:roles).and_return(["hbx_staff"])
      expect(helper.is_readonly(CensusEmployee.new)).to eq false # readonly -> false
    end
  end

  describe "#parse_ethnicity" do
    it "should return string of values" do
      expect(helper.parse_ethnicity(["test", "test1"])).to eq "test, test1"
    end
    it "should return empty value if ethnicity is not selected" do
      expect(helper.parse_ethnicity([""])).to eq ""
    end
  end

  describe "#calculate_participation_minimum" do
    let(:plan_year_1){ double("PlanYear", eligible_to_enroll_count: 5) }
    before do
      @current_plan_year = plan_year_1
    end
    it "should  return 0 when eligible_to_enroll_count is zero" do
      expect(@current_plan_year).to receive(:eligible_to_enroll_count).and_return(0)
      expect(helper.calculate_participation_minimum).to eq 0
    end

    it "should calculate eligible_to_enroll_count when not zero" do
      expect(helper.calculate_participation_minimum).to eq 3
    end
  end

  describe "#find_document" do
    context "consumer role does not have any vlp_documents" do
      it "it creates and returns an empty document of given subject" do
        doc = find_document(ConsumerRole.new, "Certificate of Citizenship")
        expect(doc).to be_a_kind_of(VlpDocument)
        expect(doc.subject).to eq("Certificate of Citizenship")
      end
    end

    context "consumer role has a vlp_document" do
      it "it returns the document" do
        consumer_role = ConsumerRole.new
        document = consumer_role.vlp_documents.build({subject:"Certificate of Citizenship"})
        found_document = find_document(consumer_role, "Certificate of Citizenship")
        expect(found_document).to be_a_kind_of(VlpDocument)
        expect(found_document).to eq(document)
        expect(found_document.subject).to eq("Certificate of Citizenship")
      end
    end
  end

  describe "#generate_options_for_effective_on_kinds" do
    it "it should return blank array" do
      options = generate_options_for_effective_on_kinds([], TimeKeeper.date_of_record)
      expect(options).to eq []
    end

    it "it should return options" do
      options = generate_options_for_effective_on_kinds(['date_of_event', 'fixed_first_of_next_month'], TimeKeeper.date_of_record)
      date = TimeKeeper.date_of_record
      expect(options).to eq [["Date of event(#{date.to_s})", 'date_of_event'], ["Fixed first of next month(#{(date.end_of_month+1.day).to_s})", 'fixed_first_of_next_month']]
    end
  end
end
