# frozen_string_literal: true

require "spec_helper"

RSpec.describe BenefitMarkets::Validators::Products::PremiumTableContract do

  let(:effective_date)      { TimeKeeper.date_of_record.next_month.beginning_of_month }
  let(:effective_period)    { effective_date.beginning_of_year..(effective_date.end_of_year) }
  let(:premium_tuples)      { {age: 12, cost: 227.07} }
  let(:rating_area)         { {} }

  let(:missing_params)      { {effective_period: effective_period, premium_tuples: premium_tuples} }
  let(:invalid_params)      { {premium_tuples: premium_tuples, effective_period: effective_date, rating_area: {}} }
  let(:error_message1)      { {:rating_area => ["is missing"]} }
  let(:error_message2)      { {:effective_period => ["must be Range"], :rating_area => ["must be filled"]} }

  context "Given invalid required parameters" do
    context "sending with missing parameters should fail validation with errors" do
      it { expect(subject.call(missing_params).failure?).to be_truthy }
      it { expect(subject.call(missing_params).errors.to_h).to eq error_message1 }
    end

    context "sending with invalid parameters should fail validation with errors" do
      it { expect(subject.call(invalid_params).failure?).to be_truthy }
      it { expect(subject.call(invalid_params).errors.to_h).to eq error_message2 }
    end
  end

  context "Given valid required parameters" do
    context "with all params" do
      let(:active_year)              { TimeKeeper.date_of_record.year }
      let(:exchange_provided_code)   { 'code' }
      let(:county_zip_ids)           { [{}] }
      let(:covered_states)           { [{}] }
      let(:required_params) do
        missing_params.merge({rating_area: {active_year: active_year, exchange_provided_code: exchange_provided_code,
                                            county_zip_ids: county_zip_ids, covered_states: covered_states}})
      end

      it "should pass validation" do
        expect(subject.call(required_params).success?).to be_truthy
        expect(subject.call(required_params).to_h).to eq required_params
      end
    end
  end
end