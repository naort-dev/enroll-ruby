module IvlHelper
	def self.individual_market_is_enabled?
		Settings.aca.market_kinds.include?("individual")
	end
	
	def individual_market_is_enabled?
		Settings.aca.market_kinds.include?("individual")
	end
end

