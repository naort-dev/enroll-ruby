module BenefitSponsors
  class ApplicationPolicy

    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end


    # Include Policy Scope
  end
end
