# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module BenefitMarkets
  module Operations
    include Dry::Monads[:result]
    include Dry::Monads::Do.for(:call)

    class CreateBenefitSponsorCatalog

      # @param [ Date ] effective_date Effective date of the benefit application
      # @param [ Hash ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
      # @param [ Array<BenefitMarkets::Entities::Locations::ServiceArea> ] benefit_market_catalog Benefit Market Catalog for the given Effective Date
      # @param [ Symbol ] market_kind Benefit Marketplace Type
      # @return [ BenefitMarkets::Entities::BenefitSponsorCatalog ] benefit_sponsor_catalog
      def call(params)
        values = yield validate(params)

        sponsor_catalog_hash = yield create_sponsor_catalog(values)
        result = yield validate_catalog(sponsor_catalog_hash)

        Success(sponsor_catalog)
      end

      private

      def validate(params)
        # effective_date = params[:effective_date]
        # validate effective date
        Success(params)
      end

      def create_sponsor_catalog(values)
        benefit_market_catalog = values[:benefit_sponsor_catalog]
        enrollment_dates = enrollment_dates_for(values)

        sponsor_catalog_hash = {
          effective_date: values[:effective_date],
          effective_period: enrollment_dates[:effective_period],
          open_enrollment_period: enrollment_dates[:open_enrollment_period],
          probation_period_kinds: benefit_market_catalog[:probation_period_kinds],
          business_policies: benefit_market_catalog[:business_policies],
          service_areas: values[:service_areas].collect(&:to_h),
          product_packages: build_product_packages(values)
        }

        Success(sponsor_catalog_hash)
      end

      def build_product_packages(values)
        values[:benefit_market_catalog][:product_packages].collect do |product_package|
          BenefitMarkets::Operations::Products::CreateProductPackage.new.call(
            values.merge({product_package: product_package, application_period: @enrollment_dates[:effective_period]})
          )
        end
      end

      def validate(params)
        contract = BenefitMarkets::Entities::Validators::BenefitSponsorshipContract.new

        Success(contract.call(params))
      end

      def enrollment_dates_for(values)
        @enrollment_dates if defined? @enrollment_dates
        @enrollment_dates = BenefitMarkets::Operations::BenefitMarketCatalog::GetEnrollmentDates.new.call(effective_date: values[:effective_date], market_kind: values[:market_kind])
      end
    end
  end
end