module BenefitSponsors
  module BenefitApplications
    class BenefitApplicationSchedular

      # TODOs
      ## handle late rate scenarios where partial or no benefit product plan/rate data exists for effective date
      ## handle midyear initial enrollments for annual fixed enrollment periods
      def effective_period_by_date(given_date = TimeKeeper.date_of_record, use_grace_period = false)
        given_day_of_month    = given_date.day
        next_month_start      = given_date.end_of_month + 1.day
        following_month_start = next_month_start + 1.month

        if given_day_of_month > open_enrollment_minimum_begin_day_of_month(use_grace_period)
          following_month_start..(following_month_start + 1.year - 1.day)
        else
          next_month_start..(next_month_start + 1.year - 1.day)
        end
      end

      def calculate_start_on_dates
        start_on = if TimeKeeper.date_of_record.day > open_enrollment_minimum_begin_day_of_month(true)
          TimeKeeper.date_of_record.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
        else
          TimeKeeper.date_of_record.prev_month.beginning_of_month + Settings.aca.shop_market.open_enrollment.maximum_length.months.months
        end

        end_on = TimeKeeper.date_of_record - Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months
        dates = (start_on..end_on).select {|t| t == t.beginning_of_month}
      end

      def enrollment_timetable_by_effective_date(effective_date)
        effective_date            = effective_date.to_date.beginning_of_month
        effective_period          = effective_date..(effective_date + 1.year - 1.day)
        open_enrollment_period    = open_enrollment_period_by_effective_date(effective_date)

        prior_month               = effective_date - 1.month
        binder_payment_due_on     = Date.new(prior_month.year, prior_month.month, Settings.aca.shop_market.binder_payment_due_on)

        open_enrollment_minimum_day     = open_enrollment_minimum_begin_day_of_month
        open_enrollment_period_minimum  = Date.new(prior_month.year, prior_month.month, open_enrollment_minimum_day)..open_enrollment_period.end

        employer_initial_application_earliest_start_on  = (effective_date + Settings.aca.shop_market.initial_application.earliest_start_prior_to_effective_on.months.months)
        employer_initial_application_earliest_submit_on = employer_initial_application_earliest_start_on
        employer_initial_application_latest_submit_on   = ("#{prior_month.year}-#{prior_month.month}-#{HbxProfile::ShopPlanYearPublishedDueDayOfMonth}").to_date

        {
          effective_date: effective_date,
          effective_period: effective_period,
          employer_initial_application_earliest_start_on: employer_initial_application_earliest_start_on,
          employer_initial_application_earliest_submit_on: employer_initial_application_earliest_submit_on,
          employer_initial_application_latest_submit_on: employer_initial_application_latest_submit_on,
          open_enrollment_period: open_enrollment_period,
          open_enrollment_period_minimum: open_enrollment_period_minimum,
          binder_payment_due_on: binder_payment_due_on,
        }
      end

      def open_enrollment_minimum_begin_day_of_month(use_grace_period = false)
        if use_grace_period
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.days
        else
          minimum_length = Settings.aca.shop_market.open_enrollment.minimum_length.adv_days
        end

        open_enrollment_end_on_day = Settings.aca.shop_market.open_enrollment.monthly_end_on
        open_enrollment_end_on_day - minimum_length
      end

      def calculate_open_enrollment_date(start_on)
        start_on = start_on.to_date

        # open_enrollment_start_on = [start_on - 1.month, TimeKeeper.date_of_record].max
        # candidate_open_enrollment_end_on = Date.new(open_enrollment_start_on.year.to_i, open_enrollment_start_on.month.to_i, Settings.aca.shop_market.open_enrollment.monthly_end_on)

        # open_enrollment_end_on = if (candidate_open_enrollment_end_on - open_enrollment_start_on) < (Settings.aca.shop_market.open_enrollment.minimum_length.days - 1)
        #   candidate_open_enrollment_end_on.next_month
        # else
        #   candidate_open_enrollment_end_on
        # end

        open_enrollment_period = open_enrollment_period_by_effective_date(start_on)


        #candidate_open_enrollment_end_on = Date.new(open_enrollment_start_on.year, open_enrollment_start_on.month, Settings.aca.shop_market.open_enrollment.monthly_end_on)

        #open_enrollment_end_on = if (candidate_open_enrollment_end_on - open_enrollment_start_on) < (Settings.aca.shop_market.open_enrollment.minimum_length.days - 1)
        #  candidate_open_enrollment_end_on.next_month
        #else
        #  candidate_open_enrollment_end_on
        #end

        binder_payment_due_date = map_binder_payment_due_date_by_start_on(start_on)

        {
          open_enrollment_start_on: open_enrollment_period.begin,
          open_enrollment_end_on: open_enrollment_period.end,
          binder_payment_due_date: binder_payment_due_date
        }
      end

      def open_enrollment_period_by_effective_date(start_on)
        open_enrollment_start_on = [(start_on - Settings.aca.shop_market.open_enrollment.maximum_length.months.months), TimeKeeper.date_of_record].max
        open_enrollment_end_on   = ("#{start_on.prev_month.year}-#{start_on.prev_month.month}-#{Settings.aca.shop_market.open_enrollment.monthly_end_on}").to_date
        open_enrollment_start_on..open_enrollment_end_on
      end

      def map_binder_payment_due_date_by_start_on(start_on)
        dates_map = {}

        {
          "2015-01-01" => '2014,12,12',
          "2015-02-01" => '2015,1,13',
          "2015-03-01" => '2015,2,12',
          "2015-04-01" => '2015,3,12',
          "2015-05-01" => '2015,4,14',
          "2015-06-01" => '2015,5,12',
          "2015-07-01" => '2015,6,12',
          "2015-08-01" => '2015,7,14',
          "2015-09-01" => '2015,8,12',
          "2015-10-01" => '2015,9,14',
          "2015-11-01" => '2015,10,14',
          "2015-12-01" => '2015,11,12',
          "2016-01-01" => '2015,12,14',
          "2016-02-01" => '2016,1,12',
          "2016-03-01" => '2016,2,12',
          "2016-04-01" => '2016,3,14',
          "2016-05-01" => '2016,4,12',
          "2016-06-01" => '2016,5,12',
          "2016-07-01" => '2016,6,14',
          "2016-08-01" => '2016,7,12',
          "2016-09-01" => '2016,8,12',
          "2016-10-01" => '2016,9,13',
          "2016-11-01" => '2016,10,12',
          "2016-12-01" => '2016,11,14',
          "2017-01-01" => '2016,12,13',
          "2017-02-01" => '2017,1,12',
          "2017-03-01" => '2017,2,14',
          "2017-04-01" => '2017,3,14',
          "2017-05-01" => '2017,4,12',
          "2017-06-01" => '2017,5,12',
          "2017-07-01" => '2017,6,13',
          "2017-08-01" => '2017,7,12',
          "2017-09-01" => '2017,8,14',
          "2017-10-01" => '2017,9,12',
          "2017-11-01" => '2017,10,12',
          "2017-12-01" => '2017,11,14',
          "2018-01-01" => '2017,12,12',
          "2018-02-01" => '2018,1,12',
          "2018-03-01" => '2018,2,13',
          "2018-04-01" => '2018,3,13',
          "2018-05-01" => '2018,4,12',
          "2018-06-01" => '2018,5,14',
          "2018-07-01" => '2018,6,12',
          "2018-08-01" => '2018,7,12',
          "2018-09-01" => '2018,8,14',
          "2018-10-01" => '2018,9,12',
          "2018-11-01" => '2018,10,12',
          "2018-12-01" => '2018,11,13',
          "2019-01-01" => '2018,12,12',
          }.each_pair do |k, v|
            dates_map[k] = Date.strptime(v, '%Y,%m,%d')
          end

        dates_map[start_on.strftime('%Y-%m-%d')] || enrollment_timetable_by_effective_date(start_on)[:binder_payment_due_date]
      end

      ## TODO - add holidays
      def first_banking_date_prior(date_value)
        date = date_value.to_date
        date = date - 1 if date.saturday?
        date = date - 2 if date.sunday?
        date
      end

      def first_banking_date_after(date_value)
        date = date_value.to_date
        date = date + 2 if date.saturday?
        date = date + 1 if date.sunday?
        date
      end
    end
  end
end
