# frozen_string_literal: true

module Factories
  # This module is for fetching IVL Eligibility for a shopping group.
  module IvlEligibilityFactory # rubocop:disable Metrics/ModuleLength
    include FloatHelper

    # returns hash of total_aptc, aptc_breakdown_by_member and csr_value
    def fetch_available_eligibility
      available_eligibility_hash = fetch_enrolling_available_aptcs.merge(fetch_csr)
      total_aptc = float_fix(available_eligibility_hash[:aptc].values.inject(0, :+))
      available_eligibility_hash.merge({:total_available_aptc => total_aptc})
    end

    def fetch_member_level_applicable_aptcs(total_aptc, age_as_of_coverage_start: false)
      thh_members = enrollment_aptc_members(shopping_tax_members)
      benchmark_hash = enrollment_eligible_benchmark_hash(thh_members, @enrollment, age_as_of_coverage_start: age_as_of_coverage_start)
      total = benchmark_hash.values.sum
      ratio_hash = {}
      benchmark_hash.each do |member_id, benchmark_value|
        ratio_hash[member_id] = (benchmark_value / total) * total_aptc
      end
      ratio_hash
    end

    # returns hash of product_id to applicable_aptc mappings
    def fetch_applicable_aptcs
      raise "Cannot process without selected_aptc: #{@selected_aptc} and product_ids: #{@product_ids}" if @selected_aptc.nil? || @product_ids.empty?

      @available_aptc ||= fetch_available_eligibility[:total_available_aptc]

      # TODO: Return a has of plan_id, applicable aptcs.
      @product_ids.inject({}) do |products_aptcs_hash, product_id|
        product_aptc = applicable_aptc_hash(product_id)
        products_aptcs_hash.merge!(product_aptc) unless product_aptc.empty?
        products_aptcs_hash
      end
    end

    def fetch_aptc_per_member
      raise "Cannot process without selected_aptc: #{@selected_aptc} and product_ids: #{@product_ids}" if @selected_aptc.nil? || @product_ids.empty?

      @product_ids.inject({}) do |member_hash, product_id|
        member_hash[product_id] = all_members_aptc(product_id)
        member_hash
      end
    end

    def fetch_elected_aptc_per_member
      raise 'Cannot process without selected_aptc' if @selected_aptc.nil?

      @enrollment.hbx_enrollment_members.inject({}) do |aptc_hash, member|
        fm_id = member.applicant_id.to_s
        aptc_hash[member.id.to_s] = if fetch_member_ratio[fm_id]
                                      @selected_aptc * fetch_member_ratio[fm_id]
                                    else
                                      0.00
                                    end
        aptc_hash
      end
    end

    def fetch_max_aptc
      tax_households.first.latest_eligibility_determination.max_aptc.to_f
    end

    private

    def fetch_member_ratio
      return @fetch_member_ratio if @fetch_member_ratio.present?

      # aptc_enr_members = aptc_enrolling_members(all_aptc_thhms)
      @fetch_member_ratio ||= aptc_benchmark_ratio_hash_test
    end

    def applicable_aptc(product_id)
      return @applicable_aptc if @applicable_aptc

      @applicable_aptc ||= fetch_applicable_aptcs[product_id.to_s]
    end

    def all_members_aptc(product_id)
      @enrollment.hbx_enrollment_members.inject({}) do |aptc_hash, member|
        fm_id = member.applicant_id.to_s
        aptc_hash[fm_id] = if fetch_member_ratio[fm_id]
                             member_cost = applicable_aptc(product_id) * fetch_member_ratio[fm_id]
                             if @can_round_off_cents
                               round_down_float_two_decimals(member_cost)
                             else
                               member_cost
                             end
                           else
                             0.00
                           end

        aptc_hash
      end
    end

    def applicable_aptc_hash(product_id)
      # We still consider AvailableAptc in this calculation because the
      # :applied_aptc(ElectedAptc) is given externally for Passive Renewals
      # and not calculated by the EA.

      product = fetch_product(product_id)
      return { product_id => 0.00 } unless product.can_use_aptc?

      ehb_premium = total_ehb_premium(product_id)
      applicable_aptc = [@available_aptc, @selected_aptc, ehb_premium].min
      @can_round_off_cents = @selected_aptc > ehb_premium
      {product_id => applicable_aptc}
    end

    def set_applicable_aptc_attrs(selected_aptc, product_ids)
      @selected_aptc = selected_aptc
      @product_ids = product_ids
    end

    def total_ehb_premium(product_id)
      product = fetch_product(product_id)
      cost_decorator = @enrollment.ivl_decorated_hbx_enrollment(product)
      round_down_float_two_decimals(cost_decorator.total_ehb_premium)
    end

    def fetch_product(product_id)
      ::BenefitMarkets::Products::Product.find(product_id)
    end

    def shopping_member_ids
      @enrollment.hbx_enrollment_members.pluck(:applicant_id).map(&:to_s)
    end

    def tax_households
      # TODO: Refactor this accordingly once FAA is enabled .
      @family.active_household.latest_active_tax_household_with_year(@enrollment.effective_on.year).to_a.compact
    end

    def shopping_tax_members
      tax_households.flat_map(&:tax_members).select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) }
    end

    def any_aptc_ineligible?
      shopping_tax_members.map(&:is_ia_eligible?).include?(false)
    end

    def enrollment_aptc_members(aptc_thhms)
      aptc_thhms.select { |thhm| shopping_member_ids.include?(thhm.applicant_id.to_s) && thhm.is_ia_eligible? }
    end

    def enrollment_eligible_benchmark_hash(thhms, enrollment, age_as_of_coverage_start: false)
      thhms.inject({}) do |benchmark_hash, thhm|
        enr_member = enrollment.hbx_enrollment_members.select{|hem| hem.person.hbx_id == thhm.person.hbx_id}.first
        date_for_age_on = age_as_of_coverage_start ? enr_member.coverage_start_on : enrollment.effective_on
        benchmark_hash.merge!({ thhm.applicant_id.to_s => thhm.aptc_benchmark_amount(enrollment, date_for_age_on) })
      end
    end

    def all_aptc_thhms
      thhms = tax_households.flat_map(&:tax_household_members)
      enrollment_aptc_members(thhms)
    end

    def aptc_enrolling_members(aptc_thhms)
      aptc_fm_ids = aptc_thhms.map(&:applicant_id).map(&:to_s)
      @enrollment.hbx_enrollment_members.select{ |member| aptc_fm_ids.include?(member.applicant_id.to_s) }
    end

    def aptc_benchmark_ratio_hash_test
      member_benchmark_hash = all_aptc_thhms.inject({}) do |b_hash, aptc_thhm|
        b_hash[aptc_thhm.family_member_id.to_s] = aptc_thhm.aptc_benchmark_amount(@enrollment)
        b_hash
      end
      total_benchmark = member_benchmark_hash.values.sum
      all_aptc_thhms.inject({}) do |members_ratio_hash, aptc_thhm|
        family_member_id = aptc_thhm.applicant_id.to_s
        members_ratio_hash[family_member_id] = (member_benchmark_hash[family_member_id] / total_benchmark)
        members_ratio_hash
      end
    end

    def tax_members_aptc_breakdown(tax_household)
      total_thh_available_aptc = tax_household.total_aptc_available_amount_for_enrollment(@enrollment, @effective_on, @excluding_enrollment_id)
      aptc_thhms = tax_household.aptc_members
      enrolling_aptc_members = enrollment_aptc_members(aptc_thhms)
      member_benchmark_hash = enrollment_eligible_benchmark_hash(enrolling_aptc_members, @enrollment)
      total_eligible_benchmark = member_benchmark_hash.values.sum

      enrolling_aptc_members.inject({}) do |thh_hash, thh_member|
        fm_id = thh_member.applicant_id.to_s
        member_ratio = (member_benchmark_hash[fm_id] / total_eligible_benchmark)
        thh_hash.merge!({ fm_id => (total_thh_available_aptc * member_ratio) })
      end
    end

    def fetch_enrolling_available_aptcs
      aptc_breakdowns = tax_households.inject({}) do |tax_members_aptcs, tax_household|
        aptc_hash = tax_members_aptc_breakdown(tax_household)
        tax_members_aptcs.merge!(aptc_hash) unless aptc_hash.empty?
        tax_members_aptcs
      end

      # If any of the shopping members does not exist in any of
      # the tax households then member is assigned with 0 aptc value
      shopping_member_ids.each do |member_id|
        aptc_breakdowns[member_id] = 0.00 unless aptc_breakdowns.keys.include?(member_id)
      end

      {:aptc => aptc_breakdowns}
    end

    def fetch_csr
      return {:csr => 'csr_0'} if (shopping_tax_members.count != shopping_member_ids.count) || any_aptc_ineligible?
      # picks csr_kind based on individual level

      csr_kind = tax_households.last.eligibile_csr_kind(shopping_member_ids)
      {:csr => csr_kind }
    end
  end
end
