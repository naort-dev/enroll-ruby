# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Households
    class DeactivateFinancialAssistanceEligibility
      send(:include, Dry::Monads[:result, :do])

      #params: {family_id , date}
      def call(params:)
        values = yield validate(params)
        result = yield execute(values)

        Success(result)
      end

      private

      def validate(params)
        if params[:family_id]&.is_a?(BSON::ObjectId) && params[:date].present?
          Success(params)
        else
          Failure('family_id is expected in BSON format and date in required')
        end
      end

      def execute(values)
        family = yield get_family(values[:family_id])
        tax_households = yield find_tax_households(family, date)
        result = yield deactivate_tax_households(tax_households, date)

        Success(result)
      end

      def get_family(family_id:)
        Operations::Families::Find.new.call(id: BSON::ObjectId(family_id))
      end

      def find_tax_households(family, date)
        result = family.active_household.latest_tax_households_with_year(date.year)

        Success(result)
      end

      def deactivate_tax_households(tax_households, date)
        result = tax_households.update_all(effective_ending_on: date)

        Success(result)
      end
    end
  end
end
