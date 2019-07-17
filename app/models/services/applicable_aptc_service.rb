# frozen_string_literal: true

module Services
  class ApplicableAptcService

    def initialize(enrollment_id, selected_aptc, product_ids)
      @enrollment_id = enrollment_id
      @selected_aptc = selected_aptc
      @product_ids = fetch_product_ids
    end

    def applicable_aptcs
      factory_instance = factory_klass.new(@enrollment_id, @selected_aptc, @product_ids)
      factory_instance.fetch_applicable_aptcs
    end

    private

    def fetch_product_ids
      product_ids.map(&:to_s)
    end

    def factory_klass
      Factories::EligibilityFactory
    end
  end
end
