module BenefitSponsors
  module PricingCalculators
    class CcaCompositeTierPrecalculator < PricingCalculator
      class CalculatorState
        attr_reader :total

        def initialize(p_calculator, product, p_model, r_coverage, gs_factor, pp_factor, sc_factor)
          @pricing_calculator = p_calculator
          @pricing_model = p_model
          @relationship_totals = Hash.new { |h, k| h[k] = 0 }
          @total = 0.00
          @rate_schedule_date = r_coverage.rate_schedule_date
          @eligibility_dates = r_coverage.coverage_eligibility_dates
          @coverage_start_date = r_coverage.coverage_start_date
          @rating_area = r_coverage.rating_area
          @product = product
          @group_size_factor = gs_factor
          @participation_percent_factor = pp_factor
          @sic_code_factor = sc_factor
        end

        def add(member)
          coverage_age = @pricing_calculator.calc_coverage_age_for(member, @eligibility_dates, @coverage_start_date, @product, @product)
          rel = @pricing_model.map_relationship_for(member.relationship, coverage_age, member.is_disabled?)
          @relationship_totals[rel.to_s] = @relationship_totals[rel.to_s] + 1
          # TODO: make this more configurable, this is an awful hack.
          # The literal string value of "child" makes me uneasy.
          # This value should either be stored or tested for in the pricing model.
          too_many_kids_make_you_crazy = if (rel.to_s == "child")  && (@relationship_totals["child"] > 3)
                                           0.0
                                         else
                                           1.0
                                         end
          member_plan_price =  ::BenefitMarkets::Products::ProductRateCache.lookup_rate(
                                  @product,
                                  @rate_schedule_date,
                                  coverage_age,
                                  @rating_area
                               ) * too_many_kids_make_you_crazy
          member_price = BigDecimal.new((
            member_plan_price *
            @group_size_factor *
            @participation_percent_factor *
            @sic_code_factor
          ).to_s).round(2)
          @total = BigDecimal.new((@total + member_price).to_s).round(2)
          self
        end

        def rating_tier
          @rating_tier ||= begin
                             @pricing_model.pricing_units.detect do |pu|
                               pu.match?(@relationship_totals)
                             end
                           end
        end
      end

      def calculate_composite_base_rates(product, pricing_model, coverage_benefit_roster, group_size, participation_percent, sic_code)
        price_total, tier_totals = calculate_tier_totals_for(pricing_model, coverage_benefit_roster, group_size, participation_percent, sic_code)
        tier_factors = {}
        denominator = 0.00
        pricing_model.pricing_units.each do |pu|
          tier_name = pu.name
          tier_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_composite_tier_factor(product, tier_name)
          tier_factors[pu.id] = tier_factor
          denominator = denominator + (tier_totals[pu.id] * tier_factor)
        end
        basis_rate = BigDecimal.new((price_total/denominator).to_s).round(2)
        tier_rates = {}
        pricing_model.pricing_units.each do |pu|
          tier_rates[pu.id] = BigDecimal.new((basis_rate * tier_factors[pu.id]).to_s).round(2)
        end
        tier_rates
      end

      def calculate_tier_totals_for(pricing_model, coverage_benefit_roster, group_size, participation_percent, sic_code)
        price_total = 0.00
        tier_totals = Hash.new(0)
        coverage_benefit_roster.each do |cbre|
          tier, group_price = tier_and_total_for(pricing_model, cbre, group_size, participation_percent, sic_code)
          price_total = BigDecimal.new((price_total + group_price).to_s).round(2)
          tier_totals[tier.id] = tier_totals[tier.id] + 1
        end
        [price_total, tier_totals]
      end

      def tier_and_total_for(pricing_model, benefit_roster_entry, group_size, participation_percent, sic_code)
        roster_entry = benefit_roster_entry
        roster_coverage = benefit_roster_entry.roster_coverage
        members_list = [roster_entry] + roster_entry.dependents
        product = benefit_roster_entry.roster_coverage.product
        gs_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_group_size_factor(product, group_size)
        pp_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_participation_percent_factor(product, participation_percent)
        sc_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_sic_code_factor(product, sic_code)
        sorted_members = members_list.sort_by do |rm|
          coverage_age = calc_coverage_age_for(rm, roster_coverage.coverage_eligibility_dates, roster_coverage.coverage_start_date, product, product)
          [pricing_model.map_relationship_for(rm.relationship, coverage_age, rm.is_disabled?), rm.dob]
        end
        calc_state = CalculatorState.new(self, roster_coverage.product, pricing_model, roster_coverage, gs_factor, pp_factor, sc_factor)
        calc_results = sorted_members.inject(calc_state) do |calc, mem|
          calc.add(mem)
        end
        [calc_results.rating_tier, calc_results.total]
      end
    end
  end
end
