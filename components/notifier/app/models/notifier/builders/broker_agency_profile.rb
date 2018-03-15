module Notifier
  class Builders::BrokerAgencyProfile

    attr_accessor :payload, :broker_agency_profile, :merge_model

    def initialize
      data_object = Notifier::MergeDataModels::BrokerAgencyProfile.new
      data_object.mailing_address = Notifier::MergeDataModels::Address.new
      @merge_model = data_object
    end

    def resource=(resource)
      @broker_agency_profile = resource
    end

    def append_contact_details
      office_address = broker_agency_profile.organization.primary_office_location.address
      if office_address.present?
        merge_model.mailing_address = MergeDataModels::Address.new({
          street_1: office_address.address_1,
          street_2: office_address.address_2,
          city: office_address.city,
          state: office_address.state,
          zip: office_address.zip
          })
      end
    end

    def notice_date
      merge_model.notice_date = TimeKeeper.date_of_record
    end

    def first_name
      merge_model.first_name = broker_agency_profile.primary_broker_role.person.first_name
    end

    def last_name
      merge_model.last_name = broker_agency_profile.primary_broker_role.person.last_name
    end

    def last_broker_agency_account
      employer.broker_agency_accounts.unscoped.reject{ |account| account.is_active? }.last
    end

    def employer
      if payload['event_object_kind'].constantize == EmployerProfile
        employer = EmployerProfile.find payload['event_object_id']
      end
    end

    def employer_name
      merge_model.employer_name = employer.legal_name
    end

    def employer_poc_firstname
      merge_model.employer_poc_firstname = employer.staff_roles.first.first_name
    end

    def employer_poc_lastname
      merge_model.employer_poc_lastname = employer.staff_roles.first.last_name
    end

    def assignment_date
      merge_model.assignment_date = employer.active_broker_agency_account.start_on if employer.active_broker_agency_account
    end

    def termination_date
      merge_model.termination_date = last_broker_agency_account.end_on if last_broker_agency_account
    end

    def broker_agency_name
      merge_model.broker_agency_name = broker_agency_profile.legal_name
    end
  end
end