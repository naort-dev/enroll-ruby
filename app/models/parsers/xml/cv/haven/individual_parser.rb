# frozen_string_literal: true

module Parsers
  module Xml
    module Cv
      module Haven
        class IndividualParser
          include HappyMapper
          register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
          namespace 'n1'

          tag 'individual'
          element :individual_id, String, tag: 'id/n1:id'
          has_one :person, Parsers::Xml::Cv::Haven::PersonParser, tag: 'person', namespace: 'n1'
          has_one :person_demographics, Parsers::Xml::Cv::Haven::PersonDemographicsParser, tag: 'person_demographics'
        end
      end
    end
  end
end
