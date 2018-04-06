module BenefitMarkets
  module Products
    module HealthProducts
      class CompositeHealthProductPackage < ::BenefitMarkets::Products::ProductPackage
        def all_products
          super().where("coverage_kind" => "health")
        end
      end
    end
  end
end
