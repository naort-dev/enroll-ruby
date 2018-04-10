module BenefitSponsors
  module ContributionCalculators
    class CcaShopReferencePlanContributionCalculator < ContributionCalculator
      ContributionResult = Struct.new(:total_contribution, :member_contributions)
      ContributionEntry = Struct.new(
       :roster_coverage,
       :relationship,
       :dob,
       :member_id,
       :dependents,
       :roster_entry_pricing,
       :roster_entry_contribution,
       :disabled
      ) do
        def is_disabled?
          disabled
        end
      end
      class CalculatorState
        attr_reader :total_contribution
        attr_reader :member_contributions

        def initialize(c_calc, c_model, m_prices, r_coverage, r_product, l_map, sc_factor, gs_factor)
          @rate_schedule_date = r_coverage.rate_schedule_date
          @contribution_model = c_model
          @contribution_calculator = c_calc
          @total_contribution = 0.00
          @member_prices = m_prices
          @member_contributions = {}
          @reference_product = r_product
          @eligibility_dates = r_coverage.coverage_eligibility_dates
          @coverage_start_on = r_coverage.coverage_start_date
          @rating_area = r_coverage.rating_area
          @level_map = l_map
          @sic_code_factor = sc_factor
          @group_size_factor = gs_factor
          @product = r_coverage.product
          @previous_product = r_coverage.previous_eligibility_product
        end

        def add(member)
          c_factor = contribution_factor_for(member)
          c_amount = calc_contribution_amount_for(member, c_factor)
          @member_contributions[member.member_id] = c_amount 
          @total_contribution = BigDecimal.new((@total_contribution + c_amount).to_s).round(2)
          self
        end

        def calc_contribution_amount_for(member, c_factor)
          member_price = @member_prices[member.member_id]
          if (member_price == 0.00) || (c_factor == 0)
            0.00
          end
          ref_rate = reference_rate_for(member)
          ref_contribution = BigDecimal.new((ref_rate * c_factor * @sic_code_factor * @group_size_factor).to_s).round(2)
          if member_price <= ref_contribution
            member_price
          else
            ref_contribution
          end
        end

        def reference_rate_for(member)
          ::BenefitMarkets::Products::ProductRateCache.lookup_rate(
            @reference_product,
            @rate_schedule_date,
            @contribution_calculator.calc_coverage_age_for(@eligibility_dates, @coverage_start_on, member, @product, @previous_product),
            @rating_area
          )
        end

        def contribution_factor_for(roster_entry_member)
          cu = get_contribution_unit(roster_entry_member)
          cl = @level_map[cu.id]
          cl.contribution_factor
        end

        def get_contribution_unit(roster_entry_member)
          coverage_age = @contribution_calculator.calc_coverage_age_for(@eligibility_dates, @coverage_start_on, roster_entry_member, @product, @previous_product)
          rel_name = @contribution_model.map_relationship_for(roster_entry_member.relationship, coverage_age, roster_entry_member.is_disabled?)
          @contribution_model.contribution_units.detect do |cu|
            cu.match?({rel_name.to_s => 1})
          end
        end
      end

      def initialize
        @level_map = {}
      end

      # Calculate contributions for the given entry
      # @param contribution_model [BenefitMarkets::ContributionModel] the
      #   contribution model for this calculation
      # @param priced_roster_entry [BenefitMarkets::SponsoredBenefits::PricedRosterEntry]
      #   the roster entry for which to provide contribution
      # @param sponsor_contribution [BenefitSponsors::SponsoredBenefits::SponsorContribution]
      #   the concrete values for contributions
      # @return [BenefitMarkets::SponsoredBenefits::ContributionRosterEntry] the
      #   contribution results paired with the roster
      def calculate_contribution_for(contribution_model, priced_roster_entry, sponsor_contribution)
        reference_product = sponsor_contribution.reference_product
        group_size_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_group_size_factor(reference_product, 1)
        sic_code_factor = ::BenefitMarkets::Products::ProductFactorCache.lookup_sic_code_factor(reference_product, sponsor_contribution.sic_code)
        level_map = level_map_for(sponsor_contribution)
        state = CalculatorState.new(
          self,
          contribution_model,
          priced_roster_entry.roster_entry_pricing.member_pricing,
          priced_roster_entry.roster_coverage,
          reference_product,
          level_map
        )
        member_list = [priced_roster_entry] + priced_roster_entry.dependents
        member_list.each do |member|
          state.add(member)
        end
        roster_entry_contribution = ContributionResult.new(
          state.total_contribution,
          state.member_contributions
        )
        ContributionEntry.new(
          priced_roster_entry.roster_coverage,
          priced_roster_entry.relationship,
          priced_roster_entry.dob,
          priced_roster_entry.member_id,
          priced_roster_entry.dependents,
          priced_roster_entry.roster_entry_pricing,
          roster_entry_contribution,
          sic_code_factor,
          priced_roster_entry.is_disabled?
        )
      end

      protected

      def level_map_for(sponsor_contribution)
        @level_map[sponsor_contribution.id] ||= sponsor_contribution.contribution_levels.inject({}) do |acc, cl|
          acc[cl.contribution_unit_id] = cl
          acc
        end
      end
    end
  end
end
