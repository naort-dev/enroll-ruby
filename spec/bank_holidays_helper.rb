module BankHolidaysHelper

  def nth_wday(n, wday, month, year)
    t = Time.local year, month, 1
    first = t.wday
      if first == wday
        fwd = 1
      elsif first < wday
        fwd = wday - first + 1
      elsif first > wday
        fwd = (wday+7) - first + 1
      end
      target = fwd + (n-1)*7
      begin
        t2 = Time.local year, month, target
      rescue ArgumentError
      return nil
      end
      if t2.mday == target
        t2
      else
        nil
      end
  end

  def binder_pay_month
    binding.pry
   due = TimeKeeper.date_of_record.month + 2
    if due == 11 || due == 12
        binder_paid_due = due - 10
    else
        binder_paid_due = due
    end
  end

  def binder_pay
    event_arr = [{event_name: "New Year's Day", event_date: schedule_time(Date.new(Date.today.year, 01, 01))}, {event_name: "Martin birthday", event_date: nth_wday(3, 1, 1, Date.today.year)}, {event_name: "President's Day", event_date: nth_wday(3, 1, 2, Date.today.year)}, {event_name: "Memorial Day", event_date: last_monday_may(Date.today.year, 5, 31)}, {event_name: "Labor day", event_date: nth_wday(1, 1, 9, Date.today.year)}, {event_name: "Columbus Day", event_date: nth_wday(2, 1, 10, Date.today.year)}, {event_name: "Veterans Day", event_date: schedule_time(Date.new(Date.today.year, 11, 11))}, {event_name: "Thanksgiving Day", event_date: nth_wday(4, 4, 11, Date.today.year)}, {event_name: "Christmas Day", event_date: schedule_time(Date.new(Date.today.year, 12, 25))}, {event_name: "Independence Day", event_date: schedule_time(Date.new(Date.today.year, 07, 04))}]
    event_date_arr = event_arr.map{|hsh| schedule_time(hsh[:event_date])}

    to_date = Date.new(TimeKeeper.date_of_record.year,binder_pay_month - 1, Settings.aca.shop_market.binder_payment_due_on)

    while (event_date_arr.include?(to_date) or to_date.wday > 5)
      to_date = to_date+1.day
    end  
    to_date
  end
end
