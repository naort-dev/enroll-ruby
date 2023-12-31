module Importers::Mhc
  class ConversionEmployeeSet
    
    def headers
      default_headers = [
        "Action",
        "Type of Enrollment",
        "Market",
        "Sponsor Name",
        "FEIN",
        "Issuer Assigned Employer ID",
        "Hire Date",
        "Benefit Begin Date",
        "Plan Name",
        "HIOS Id",
        "(AUTO) Premium Total",
        "Employer Contribution",
        "(AUTO) Employee Responsible Amt",
        "Subscriber SSN",
        "Subscriber DOB",
        "Subscriber Gender",
        "Subscriber First Name",
        "Subscriber Middle Name",
        "Subscriber Last Name",
        "Subscriber Email",
        "Subscriber Phone",
        "Subscriber Address 1",
        "Subscriber Address 2",
        "Subscriber City",
        "Subscriber State",
        "Subscriber Zip",
        "SELF (only one option)"
      ]
      dep_headers = []
      @dependents.times do |i|
        ["SSN", "DOB", "Gender", "First Name", "Middle Name", "Last Name", "Email", "Phone", "Address 1", "Address 2", "City", "State", "Zip", "Relationship"].each do |h|
            dep_headers << "Dep#{i+1} #{h}"
        end
      end
      default_headers + dep_headers + ["Import Status", "Import Details"]
    end

    def row_mapping
      default_rows = [
        :action,
        :ignore,
        :ignore,
        :employer_name,
        :fein,
        :ignore,
        :hire_date,
        :benefit_begin_date,
        :ignore,
        :ignore,
        :ignore,
        :ignore,
        :ignore,
        :subscriber_ssn,
        :subscriber_dob,
        :subscriber_gender,
        :subscriber_name_first,
        :subscriber_name_middle,
        :subscriber_name_last,
        :subscriber_email,
        :subscriber_phone,
        :subscriber_address_1,
        :subscriber_address_2,
        :subscriber_city,
        :subscriber_state,
        :subscriber_zip,
        :ignore
      ]
      dep_rows = []
      @dependents.times do |i|
        ["ssn", "dob", "gender", "name_first", "name_middle", "name_last", "email", "phone", "address_1", "address_2", "city", "state", "zip", "relationship"].each do |r|
            dep_rows << "dep_#{i+1}_#{r}".to_sym
        end
      end
      default_rows + dep_rows
    end

    include ::Importers::RowSet

    def initialize(file_name, o_stream, default_hire_date, dependents)
      @default_hire_date = default_hire_date
      @spreadsheet = Roo::Spreadsheet.open(file_name)
      @out_stream = o_stream
      @out_csv = CSV.new(o_stream)
      @dependents = dependents
    end

    def create_model(record_attrs)
      # puts "processing #{record_attrs[:subscriber_name_first]}--#{record_attrs[:subscriber_name_last]}"
      the_action = record_attrs[:action].blank? ? "add" : record_attrs[:action].to_s.strip.downcase
      case the_action
      # when "update"
      #   ::Importers::ConversionEmployeeAction.new(record_attrs.merge({:default_hire_date => @default_hire_date}))
      when "delete"
        ::Importers::ConversionEmployeeDelete.new(record_attrs.merge({:default_hire_date => @default_hire_date}))
      else
        ::Importers::ConversionEmployeeAction.new(record_attrs.merge({:default_hire_date => @default_hire_date}))
      end
    end
  end
end
