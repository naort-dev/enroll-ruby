class UnassistedPlanCostDecorator < SimpleDelegator
  include FloatHelper

  attr_reader :hbx_enrollment
  attr_reader :elected_aptc
  attr_reader :tax_household

  def initialize(plan, hbx_enrollment, elected_aptc=0, tax_household=nil)
    super(plan)
    @hbx_enrollment = hbx_enrollment
    @elected_aptc = elected_aptc.to_f
    @tax_household = tax_household
  end

  def members
    hbx_enrollment.hbx_enrollment_members
  end

  def schedule_date
    @hbx_enrollment.effective_on
  end

  def age_of(member)
    member.age_on_effective_date
  end

  def child_index(member)
    @children = members.select(){|member| age_of(member) < 21} unless defined?(@children)
    @children.index(member)
  end

  def large_family_factor(member)
    if (age_of(member) > 20) || (kind == :dental)
      1.00
    else
      if child_index(member) > 2
        0.00
      else
        1.00
      end
    end
  end

  #TODO: FIX me to refactor hard coded rating area
  def premium_for(member)
    (::BenefitMarkets::Products::ProductRateCache.lookup_rate(__getobj__, schedule_date, age_of(member), "R-DC001") * large_family_factor(member)).round(2)
  end

  def employer_contribution_for(member)
    0.00
  end

  def aptc_amount(member)
    if @tax_household.present? && @tax_household.is_member_aptc_eligible?(member.family_member)
      unchecked_eligible_fms = @tax_household.find_aptc_family_members(members.map(&:family_member))
      aptc_ratio = ((member.family_member.aptc_benchmark_amount(@hbx_enrollment))/@tax_household.total_benchmark_amount(unchecked_eligible_fms, @hbx_enrollment))
      applicable_aptc_for_member = @elected_aptc * aptc_ratio
      member_premium = premium_for(member)
      if applicable_aptc_for_member > member_premium
        applicable_aptc_for_member = member_premium * __getobj__.ehb
      end
      applicable_aptc_for_member
    else
      0.00
    end
  end

  def employee_cost_for(member)
    cost = (premium_for(member) - aptc_amount(member)).round(2)
    cost = 0.00 if cost < 0
    (cost * large_family_factor(member)).round(2)
  end

  def total_premium
    members.reduce(0.00) do |sum, member|
      (sum + premium_for(member)).round(2)
    end
  end
  def total_employer_contribution
    0.00
  end

  def total_aptc_amount
    members.reduce(0.00) do |sum, member|
      (sum + aptc_amount(member)).round(2)
    end.round(2)
  end

  def total_employee_cost
    members.reduce(0.00) do |sum, member|
      (sum + employee_cost_for(member)).round(2)
    end.round(2)
  end

  def total_ehb_premium
    members.reduce(0.00) do |sum, member|
      (sum + round_down_float_two_decimals(member_ehb_premium(member)))
    end
  end

  def member_ehb_premium(member)
    premium_for(member) * __getobj__.ehb
  end
end
