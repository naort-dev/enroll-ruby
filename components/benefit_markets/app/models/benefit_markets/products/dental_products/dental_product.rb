module BenefitMarkets
  module Products
    class DentalProducts::DentalProduct < BenefitMarkets::Products::Product

      PRODUCT_PACKAGE_KINDS = [:single_product, :multi_product]


      field :hios_id,                     type: String
      field :hios_base_id,                type: String
      field :csr_variant_id,              type: String

    end
  end
end
