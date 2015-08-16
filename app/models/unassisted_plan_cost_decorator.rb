class UnassistedPlanCostDecorator < SimpleDelegator
  attr_reader :member_provider

  def initialize(plan, hbx_enrollment)
    super(plan)
    @member_provider = hbx_enrollment
  end

  def members
    member_provider.hbx_enrollment_members
  end

  def plan_year_start_on
    TimeKeeper.date_of_record.beginning_of_year
  end

  def age_of(member)
    member.age_on_effective_date
  end

  def premium_for(member)
    __getobj__.premium_for(plan_year_start_on, age_of(member))
  end

  def total_premium
    members.reduce(0) do |sum, member|
      sum + premium_for(member)
    end
  end
end
