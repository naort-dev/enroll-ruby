module IndividualMarketBehaviors
  extend ActiveSupport::Concern

  included do

  end

  class_methods do
    def individual_market_is_enabled?
      Settings.aca.market_kinds.include? "individual"
    end
  end
end
