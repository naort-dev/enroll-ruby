module Notifier
  class MergeDataModels::EmployeeProfile
    include Virtus.model
    include ActiveModel::Model
    include Notifier::MergeDataModels::TokenBuilder

    attribute :notice_date, Date
    attribute :first_name, String
    attribute :last_name, String
    attribute :mailing_address, MergeDataModels::Address
    attribute :employer_name, String
    attribute :coverage_begin_date, Date
    attribute :broker, MergeDataModels::Broker
    attribute :date_of_hire, Date
    attribute :earliest_coverage_begin_date, Date
    attribute :new_hire_oe_end_date, Date
    attribute :addresses, Array[MergeDataModels::Address]

  
    def self.stubbed_object
      notice = Notifier::MergeDataModels::EmployeeProfile.new({
        notice_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        first_name: 'John',
        last_name: 'Whitmore',
        employer_name: 'MA Health Connector',
        coverage_begin_date: TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        date_of_hire: TimeKeeper.date_of_record.strftime('%m/%d/%Y') ,
        earliest_coverage_begin_date: TimeKeeper.date_of_record.next_month.beginning_of_month.strftime('%m/%d/%Y'),
        new_hire_oe_end_date: (TimeKeeper.date_of_record + 30.days).strftime('%m/%d/%Y')
      })
      notice.mailing_address = Notifier::MergeDataModels::Address.new
      notice.broker = Notifier::MergeDataModels::Broker.new
      notice.addresses = [ notice.mailing_address ]
      notice
    end

    def collections
      []
    end

    def conditions
      %w{broker_present?}
    end

    def broker_present?
      self.broker.present?
    end
  end
end