require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationSchedular, type: :model, :dbclean => :after_each do
    subject {::BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new}

    describe "#map_binder_payment_due_date_by_start_on" do
      let(:benefit_application_schedular) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new }
      let(:date_hash) do
        {

          "2018-08-01" => '2018,7,24',
          "2018-09-01" => '2018,8,23',
          "2018-10-01" => '2018,9,24',
          "2018-11-01" => '2018,10,23',
          "2018-12-01" => '2018,11,26',
          "2019-01-01" => '2018,12,26',
          "2019-02-01" => '2019,1,23',
          "2019-03-01" => '2019,2,25',
          "2019-04-01" => '2019,3,25',
          "2019-05-01" => '2019,4,23',
          "2019-06-01" => '2019,5,23',
          "2019-07-01" => '2019,6,24',
          "2019-08-01" => '2019,7,23',
          "2019-09-01" => '2019,8,23',
          "2019-10-01" => '2019,9,23',
          "2019-11-01" => '2019,10,23',
          "2019-12-01" => '2019,11,25',
          "2020-01-01" => '2019,12,24',
          "2020-02-01" => '2020,1,23',
          "2020-03-01" => '2020,2,24',
          "2020-04-01" => '2020,3,23',
          "2020-05-01" => '2020,4,23',
          "2020-06-01" => '2020,5,22',
          "2020-07-01" => '2020,6,23',
          "2020-08-01" => '2020,7,23',
          "2020-09-01" => '2020,8,24',
          "2020-10-01" => '2020,9,23',
          "2020-11-01" => '2020,10,23',
          "2020-12-01" => '2020,11,24',
          "2021-01-01" => '2020,12,23'
        }
      end

      context 'when start on in hash key' do
        it 'should return the corresponding value' do
          date_hash.each do |k, v|
            expect(benefit_application_schedular.map_binder_payment_due_date_by_start_on(Date.parse(k))).to eq(Date.strptime(v, '%Y,%m,%d'))
          end
        end
        it { expect(benefit_application_schedular.map_binder_payment_due_date_by_start_on(Date.parse('2018-11-01'))).to eq(Date.parse('2018-10-23')) }
      end
    end

    describe 'start_on_options_with_schedule' do
      let(:dates_hash) { subject.start_on_options_with_schedule(true) }

      it 'should return a instance of Hash' do
        expect(dates_hash).to be_a Hash
      end

      it 'should have sub keys' do
        [:open_enrollment_start_on, :open_enrollment_end_on].each do |dt_key|
          expect(dates_hash.values.first.has_key?(dt_key)).to be_truthy
        end
      end

      it "should return today's date for start_on" do
        expect(dates_hash.values.first[:open_enrollment_start_on]).to eq TimeKeeper.date_of_record
      end
    end

    describe 'calculate_start_on_dates' do
      let(:previous_date) { Date.new(2019, 01, 02) }
      let(:later_date) { Date.new(2019, 01, 28) }
      let(:both_dates) { [Date.new(2019, 02, 01), Date.new(2019, 03, 01)] }

      context 'after open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(later_date)
        end

        context 'not an admin data table action' do
          it 'should return 1 date' do
            expect(subject.calculate_start_on_dates).to eq [Date.new(2019, 03, 01)]
          end
        end

        context 'not an admin data table action' do
          it 'should return 2 dates' do
            expect(subject.calculate_start_on_dates(true)).to eq both_dates
          end
        end
      end

      context 'before open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(previous_date)
        end

        context 'not an admin data table action' do
          it 'should return 1 date' do
            expect(subject.calculate_start_on_dates).to eq both_dates
          end
        end

        context 'not an admin data table action' do
          it 'should return 2 dates' do
            expect(subject.calculate_start_on_dates(true)).to eq both_dates
          end
        end
      end
    end

    describe 'open_enrollment_period_by_effective_date' do
      let(:start_on) { Date.new(2019, 02, 01) }
      let(:previous_date) { Date.new(2019, 01, 02) }
      let(:later_date) { Date.new(2019, 01, 28) }
      let(:default_monthly_end_on_date) { Date.new(2019, 01, Settings.aca.shop_market.open_enrollment.monthly_end_on) }
      let(:oe_min_days) { Settings.aca.shop_market.open_enrollment.minimum_length.days }

      context 'after open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(later_date)
        end

        context 'not an admin data table action' do
          it 'should return 1 date' do
            expect(subject.open_enrollment_period_by_effective_date(start_on, false)).to eq (later_date..default_monthly_end_on_date)
          end
        end

        context 'not an admin data table action' do
          it 'should return 2 dates' do
            expect(subject.open_enrollment_period_by_effective_date(start_on, true)).to eq (later_date..(later_date+oe_min_days))
          end
        end
      end

      context 'before open_enrollment_minimum_begin_day_of_month' do
        before :each do
          allow(TimeKeeper).to receive(:date_of_record).and_return(previous_date)
        end

        context 'not an admin data table action' do
          it 'should return 1 date' do
            expect(subject.open_enrollment_period_by_effective_date(start_on, false)).to eq (previous_date..default_monthly_end_on_date)
          end
        end

        context 'not an admin data table action' do
          it 'should return 2 dates' do
            expect(subject.open_enrollment_period_by_effective_date(start_on, true)).to eq (previous_date..default_monthly_end_on_date)
          end
        end
      end
    end
  end
end
