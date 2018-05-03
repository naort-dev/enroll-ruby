require 'rails_helper'

module BenefitMarkets
  RSpec.describe Products::PremiumTable, type: :model do

    let(:this_year)           { TimeKeeper.date_of_record.year }

    let(:premium_q1_age_20)   { BenefitMarkets::Products::PremiumTuple.new(age: 20, cost: 201) }
    let(:premium_q1_age_30)   { BenefitMarkets::Products::PremiumTuple.new(age: 30, cost: 301) }
    let(:premium_q1_age_40)   { BenefitMarkets::Products::PremiumTuple.new(age: 40, cost: 401) }

    let(:rating_area)         { BenefitMarkets::Locations::RatingArea.new }
    let(:effective_period)    { Date.new(this_year, 1, 1)..Date.new(this_year, 3, 31) }
    let(:premium_tuples)      { [premium_q1_age_20, premium_q1_age_30, premium_q1_age_40] }

    let(:params) do 
      {
        effective_period: effective_period,
        rating_area:      rating_area,
        premium_tuples:   premium_tuples,
      }
    end

    context "A new PremiumTable instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do
        context "that's missing effective_period" do
          subject { described_class.new(params.except(:effective_period)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:effective_period]).to include("can't be blank")
          end
        end

        context "that's missing rating_area" do
          subject { described_class.new(params.except(:rating_area)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:rating_area]).to include("can't be blank")
          end
        end

        context "that's missing premium_tuples" do
          subject { described_class.new(params.except(:premium_tuples)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:premium_tuples]).to include("can't be blank")
          end
        end
      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end

    end
  end
end
