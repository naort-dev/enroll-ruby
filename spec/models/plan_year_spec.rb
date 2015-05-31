require 'rails_helper'

describe PlanYear, :type => :model, :dbclean => :after_each do
  it { should validate_presence_of :start_on }
  it { should validate_presence_of :end_on }
  it { should validate_presence_of :start_on_date }
  it { should validate_presence_of :end_on_date }
  it { should validate_presence_of :open_enrollment_start_on_date }
  it { should validate_presence_of :open_enrollment_end_on_date }

  let!(:employer_profile)               { FactoryGirl.create(:employer_profile) }
  let(:valid_plan_year_start_on)        { (Date.current + 1.month).end_of_month + 1.day }
  let(:valid_plan_year_end_on)          { valid_plan_year_start_on + 1.year - 1.day }
  let(:valid_open_enrollment_start_on)  { Date.current.beginning_of_month }
  let(:valid_open_enrollment_end_on)    { valid_open_enrollment_start_on + 15.days }
  let(:valid_fte_count)                 { 5 }

  let(:valid_params) do
    {
      employer_profile: employer_profile,
      start_on: valid_plan_year_start_on,
      end_on: valid_plan_year_end_on,
      open_enrollment_start_on: valid_open_enrollment_start_on,
      open_enrollment_end_on: valid_open_enrollment_end_on,
      fte_count: valid_fte_count
    }
  end

  context ".new" do
    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(PlanYear.new(**params).save).to be_falsey
      end
    end

    context "with no employer profile" do
      let(:params) {valid_params.except(:employer_profile)}

      it "should raise" do
        expect{PlanYear.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with no start on" do
      let(:params) {valid_params.except(:start_on)}

      it "should fail validation" do
        expect(PlanYear.create(**params).errors[:start_on].any?).to be_truthy
      end
    end

    context "with no end on" do
      let(:params) {valid_params.except(:end_on)}

      it "should fail validation" do
        expect(PlanYear.create(**params).errors[:end_on].any?).to be_truthy
      end
    end

    context "with no open enrollment start on" do
      let(:params) {valid_params.except(:open_enrollment_start_on)}

      it "should fail validation" do
        #TODO no present validation on open enrollment right now
        #expect(PlanYear.create(**params).errors[:open_enrollment_start_on].any?).to be_truthy
      end
    end

    context "with no open enrollment end on" do
      let(:params) {valid_params.except(:open_enrollment_end_on)}

      it "should fail validation" do
        #TODO no present validation on open enrollment end on right now
        #expect(PlanYear.create(**params).errors[:open_enrollment_end_on].any?).to be_truthy
      end
    end

    context "with all valid arguments" do
      let(:params) { valid_params }
      let(:plan_year) { PlanYear.new(**params) }

      it "should save" do
        expect(plan_year.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_plan_year) do
          py = plan_year
          py.save
          py
        end

        it "should be findable" do
          expect(PlanYear.find(saved_plan_year.id).id.to_s).to eq saved_plan_year.id.to_s
        end
      end
    end
  end

  context "a new plan year is initialized" do
    let(:plan_year) { PlanYear.new(**valid_params) }

    context "and effective date is specified" do
      context "and effective date doesn't provide enough time for enrollment" do
        pending
        context "and an employer is entering the effective date" do
          it "should fail validation" do
            # expect(plan_year.valid?).to be_falsey
            # expect(plan_year.errors[:effective_date].any?).to be_truthy
            # expect(plan_year.errors[:start_on].first).to match(/applications may not be started more than/)
          end
        end

        context "and an HbxAdmin or system service is entering the effective date" do
          pending
          it "should pass validation" do
            # expect(plan_year.valid?).to be_truthy
            # expect(plan_year.errors[:effective_date].any?).to be_truthy
          end
        end
      end

      context "and effective date does provide enough time for enrollment" do
        pending
        it "should pass validation" do
          # expect(plan_year.valid?).to be_truthy
          # expect(plan_year.errors[:effective_date].any?).to be_truthy
        end
      end
    end

    context "and an open enrollment period is specified" do
      context "and open enrollment start date is after the end date" do
        let(:open_enrollment_end_on)    { Date.current }
        let(:open_enrollment_start_on)  { open_enrollment_end_on + 1 }

        before do
          plan_year.open_enrollment_start_on = open_enrollment_start_on
          plan_year.open_enrollment_end_on = open_enrollment_end_on
        end

        it "should fail validation" do
          expect(plan_year.valid?).to be_falsey
          expect(plan_year.errors[:open_enrollment_end_on].any?).to be_truthy
        end
      end

      context "and the open enrollment period is too short" do
        let(:invalid_length)  { HbxProfile::ShopOpenEnrollmentPeriodMinimum - 1 }
        let(:open_enrollment_start_on)  { Date.current }
        let(:open_enrollment_end_on)    { open_enrollment_start_on + invalid_length }

        before do
          plan_year.open_enrollment_start_on = open_enrollment_start_on
          plan_year.open_enrollment_end_on = open_enrollment_end_on
        end

        it "should fail validation" do
          expect(plan_year.valid?).to be_falsey
          expect(plan_year.errors[:open_enrollment_end_on].any?).to be_truthy
        end
      end

      context "and the open enrollment period is too long" do
        let(:invalid_length)  { HbxProfile::ShopOpenEnrollmentPeriodMaximum + 1 }
        let(:open_enrollment_start_on)  { Date.current }
        let(:open_enrollment_end_on)    { open_enrollment_start_on + invalid_length }

        before do
          plan_year.open_enrollment_start_on = open_enrollment_start_on
          plan_year.open_enrollment_end_on = open_enrollment_end_on
        end

        it "should fail validation" do
          expect(plan_year.valid?).to be_falsey
          expect(plan_year.errors[:open_enrollment_end_on].any?).to be_truthy
        end
      end

      context "and a plan year start and end is specified" do
        context "and the plan year start date isn't first day of month" do
          let(:start_on)  { Date.current.beginning_of_month + 1 }
          let(:end_on)    { start_on + HbxProfile::ShopPlanYearPeriodMinimum }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:start_on].any?).to be_truthy
          end
        end

        context "and the plan year start date is after the end date" do
          let(:end_on)    { Date.current.beginning_of_month }
          let(:start_on)  { end_on + 1 }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:end_on].any?).to be_truthy
          end
        end

        context "and the plan year period is too short" do
          let(:invalid_length)  { HbxProfile::ShopPlanYearPeriodMinimum - 1.day }
          let(:start_on)  { Date.current.end_of_month + 1 }
          let(:end_on)    { start_on + invalid_length }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:end_on].any?).to be_truthy
          end
        end

        context "and the plan year period is too long" do
          let(:invalid_length)  { HbxProfile::ShopPlanYearPeriodMaximum + 1.day }
          let(:start_on)  { Date.current.end_of_month + 1 }
          let(:end_on)    { start_on + invalid_length }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:end_on].any?).to be_truthy
          end
        end

        context "and the plan year begins before open enrollment ends" do
          let(:valid_open_enrollment_length)  { HbxProfile::ShopOpenEnrollmentPeriodMaximum }
          let(:valid_plan_year_length)  { HbxProfile::ShopPlanYearPeriodMaximum }
          let(:open_enrollment_start_on)  { Date.current }
          let(:open_enrollment_end_on)    { open_enrollment_start_on + valid_open_enrollment_length }
          let(:start_on)  { open_enrollment_start_on - 1 }
          let(:end_on)    { start_on + valid_plan_year_length }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:start_on].any?).to be_truthy
          end
        end

        context "and the effective date is too far in the future" do
          let(:invalid_initial_application_date)  { Date.current + HbxProfile::ShopPlanYearPublishBeforeEffectiveDateMaximum.months + 1.month }
          let(:schedule)  { PlanYear.shop_enrollment_timetable(invalid_initial_application_date) }
          let(:start_on)  { schedule[:plan_year_start_on] }
          let(:end_on)    { schedule[:plan_year_end_on] }
          let(:open_enrollment_start_on) { schedule[:open_enrollment_earliest_start_on] }
          let(:open_enrollment_end_on)   { schedule[:open_enrollment_latest_end_on] }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
            plan_year.open_enrollment_start_on = open_enrollment_start_on
            plan_year.open_enrollment_end_on = open_enrollment_end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:start_on].any?).to be_truthy
            expect(plan_year.errors[:start_on].first).to match(/applications may not be started more than/)
          end
        end

        context "and the end of open enrollment is past deadline for effective date" do
          let(:schedule)  { PlanYear.shop_enrollment_timetable(Date.current) }
          let(:start_on)  { schedule[:plan_year_start_on] }
          let(:end_on)    { schedule[:plan_year_end_on] }
          let(:open_enrollment_start_on) { schedule[:open_enrollment_latest_start_on] }
          let(:open_enrollment_end_on)   { schedule[:open_enrollment_latest_end_on] + 1 }

          before do
            plan_year.start_on = start_on
            plan_year.end_on = end_on
            plan_year.open_enrollment_start_on = open_enrollment_start_on
            plan_year.open_enrollment_end_on = open_enrollment_end_on
          end

          it "should fail validation" do
            expect(plan_year.valid?).to be_falsey
            expect(plan_year.errors[:open_enrollment_end_on].any?).to be_truthy
            expect(plan_year.errors[:open_enrollment_end_on].first).to match(/open enrollment must end on or before/)
          end
        end
      end
    end
  end

  context "application is submitted to be published" do
    let(:plan_year)                   { PlanYear.new(**valid_params) }
    let(:valid_fte_count)             { HbxProfile::ShopSmallMarketFteCountMaximum }
    let(:invalid_fte_count)           { HbxProfile::ShopSmallMarketFteCountMaximum + 1 }
    let(:valid_ee_contribution_pct)   { HbxProfile::ShopEmployerContributionPercentMinimum }
    let(:invalid_ee_contribution_pct) { HbxProfile::ShopEmployerContributionPercentMinimum - 1 }

    it "plan year should be in draft state" do
      expect(plan_year.draft?).to be_truthy
    end

    context "and employer's primary office isn't located in-state" do
      before do
        plan_year.employer_profile.organization.primary_office_location.address.state = "AK"
      end

      it "application should not be valid" do
        expect(plan_year.is_application_valid?).to be_falsey
      end

      it "and should provide relevent warning message" do
        expect(plan_year.application_warnings[:primary_office_location].present?).to be_truthy
        expect(plan_year.application_warnings[:primary_office_location]).to match(/primary office must be located/)
      end
    end

    context "and benefit group is missing" do
      it "application should not be valid" do
        expect(plan_year.is_application_valid?).to be_falsey
      end

      it "and should provide relevent warning message" do
        expect(plan_year.application_warnings[:benefit_groups].present?).to be_truthy
        expect(plan_year.application_warnings[:benefit_groups]).to match(/at least one benefit group/)
      end
    end

    context "and the employer size exceeds regulatory max" do
      before do
        plan_year.fte_count = invalid_fte_count
        plan_year.publish
      end

      it "application should not be valid" do
        expect(plan_year.is_application_valid?).to be_falsey
      end

      it "and should provide relevent warning message" do
        expect(plan_year.application_warnings[:fte_count].present?).to be_truthy
        expect(plan_year.application_warnings[:fte_count]).to match(/number of full time equivalents/)
      end

      it "and plan year should be in publish pending state" do
        expect(plan_year.publish_pending?).to be_truthy
      end
    end

    context "and the employer contribution amount is below minimum" do
      let(:benefit_group) { FactoryGirl.build(:benefit_group, plan_year: plan_year) }

      before do
        benefit_group.premium_pct_as_int = HbxProfile::ShopEmployerContributionPercentMinimum - 1
      end

      context "and the effective date isn't January 1" do
        before do
          plan_year.start_on = Date.current.beginning_of_year + 1.month
          plan_year.publish
        end

        it "application should not be valid" do
          expect(plan_year.is_application_valid?).to be_falsey
        end

        it "and should provide relevent warning message" do
          expect(plan_year.application_warnings[:minimum_employer_contribution].present?).to be_truthy
          expect(plan_year.application_warnings[:minimum_employer_contribution]).to match(/employer contribution percent/)
        end

        it "and plan year should be in publish pending state" do
          expect(plan_year.publish_pending?).to be_truthy
        end
      end

      context "and the effective date is January 1" do
        before do
          plan_year.start_on = Date.current.beginning_of_year
          plan_year.publish
        end

        it "application should be valid" do
          expect(plan_year.is_application_valid?).to be_truthy
        end

        it "and plan year should be in published state" do
          expect(plan_year.published?).to be_truthy
        end
      end
    end

    context "and one or more application elements are invalid" do
      let(:benefit_group) { FactoryGirl.build(:benefit_group, plan_year: plan_year) }

      before do
        benefit_group.premium_pct_as_int = invalid_ee_contribution_pct
        plan_year.fte_count = invalid_fte_count
        plan_year.start_on = Date.current.beginning_of_year + 1.month
        plan_year.publish
      end

      it "and application should not be valid" do
        expect(plan_year.is_application_valid?).to be_falsey
      end

      it "and plan year should be in publish pending state" do
        expect(plan_year.publish_pending?).to be_truthy
      end

      context "and application is withdrawn for correction" do
        before do
          plan_year.withdraw_pending
        end

        it "plan year should be in draft state" do
          expect(plan_year.draft?).to be_truthy
        end
      end

      context "and application is submitted with warnings" do
        before do
          plan_year.force_publish
        end

        it "plan year should be in published state" do
          expect(plan_year.published?).to be_truthy
        end

        it "and employer_profile should be in ineligible state" do
          expect(plan_year.employer_profile.ineligible?).to be_truthy
        end

        pending "determination of notification form and channels"
        it "and employer should be notified that applcation is ineligible" do
        end

        context "and 30 days or less has elapsed since applicaton was submitted" do
          context "and the employer decides to appeal" do
            it "should transition to ineligible-appealing state" do
            end

            pending "determination of notification form and channels"
            it "should notify HBX representatives of appeal request" do
            end

              context "and HBX determines appeal has merit" do
                it "should transition employer status to registered" do
                end
              end

              context "and HBX determines appeal has no merit" do
                it "should transition employer status to ineligible" do
                end
              end

              context "and HBX determines application was submitted with errors" do
                it "should transition plan year application to draft" do
                end
                it "and should transition employer status to applicant" do
                end
              end
            end
          end

        context "and more than 30 days has elapsed since application was submitted" do
          pending "should employer actually move into additional 60-day wait period?"
        end
      end
    end

    context "and all application elements are valid" do
      let(:benefit_group) { FactoryGirl.build(:benefit_group, plan_year: plan_year) }

      before do
      end

      it "plan year should publish" do
        # expect(plan_year.published?).to be_truthy
      end

      it "and employer_profile should be in registered state" do
        # expect(plan_year.employer_profile.registered?).to be_truthy
      end

      context "and it is published" do
        pending
        context "and changes to plan year application should be blocked" do
        end
      end
    end
  end

end
