require "benefit_markets/engine"
require "mongoid"
require "aasm"
require 'config'

module BenefitMarkets

    BENEFIT_MARKET_KINDS    = [:aca_shop, :aca_individual, :medicaid, :medicare]
    PRODUCT_KINDS           = [:health, :dental, :medicaid, :medicare, :term_life, :short_term_disability, :long_term_disability]
    PROBATION_PERIOD_KINDS  = [:first_of_month_before_15th, :date_of_hire, :first_of_month, :first_of_month_after_30_days, :first_of_month_after_60_days]

    # Time periods when sponsors may initially offer, and subsequently renew, benefits
    #   :monthly - may start first of any month of the year and renews each year in same month
    #   :annual  - may start only on benefit market's annual effective date month and renews each year in same month
    #   :annual_with_midyear_initial - may start mid-year and renew at subsequent annual effective date month
    APPLICATION_INTERVAL_KINDS  = [:monthly, :annual, :annual_with_midyear_initial]

    
    CONTACT_METHOD_KINDS        = [:paper_and_electronic, :paper_only]


    # Isolate the namespace portion of the passed class
    def parent_namespace_for(klass)
      klass_name = klass.to_s.split("::")
      klass_name.slice!(-1) || []
      klass_name.join("::")
    end

    class << self
      attr_writer :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.reset
      @configuration = Configuration.new
    end

    def self.configure
      yield(configuration)
    end

    class Configuration
      attr_accessor :settings
    end


    # Ensure class type and integrity of date period ranges
    def self.tidy_date_range(range_period, attribute = nil)

      return range_period if (range_period.begin.class == Date) && (range_period.end.class == Date) && (range_is_increasing? range_period)

      case range_period.begin.class
      when Date
        date_range  = range_period
      when String
        begin_on    = range_period.split("..")[0]
        end_on      = range_period.split("..")[1]
        date_range  = Date.strptime(beginning)..Date.strptime(ending)
      when Time, DateTime
        begin_on    = range_period.begin.to_date
        end_on      = range_period.end.to_date
        date_range  = begin_on..end_on
      else
        # @errors.add(attribute.to_sym, "values must be Date or Time") if attribute.present?
        return nil
      end

      if range_is_increasing?(date_range)
        return date_range
      else
        # @errors.add(attribute.to_sym, "end date may not preceed begin date") if attribute.present?
        return nil
      end
    end

    def self.range_is_increasing?(range)
      range.begin < range.end
    end
end
