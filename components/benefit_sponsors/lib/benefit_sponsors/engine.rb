module BenefitSponsors
  class Engine < ::Rails::Engine
    isolate_namespace BenefitSponsors

    config.generators do |g|
      g.orm :mongoid
      g.template_engine :slim
      g.test_framework :rspec, :fixture => false
      g.fixture_replacement :factory_bot, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end

    config.to_prepare do
      BenefitSponsors::ApplicationController.helper Rails.application.helpers
    end
  end
end
