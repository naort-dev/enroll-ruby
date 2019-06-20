class MigrateDcProducts < Mongoid::Migration
  def self.up
    if Settings.site.key.to_s.downcase == "dc"
      say_with_time("Migrating plans for DC") do

        old_carrier_profile_map = {}
        CarrierProfile.all.each do |cpo|
          old_carrier_profile_map[cpo.id] = cpo.hbx_id
        end

        new_carrier_profile_map = {}
        ::BenefitSponsors::Organizations::Organization.issuer_profiles.each do |ipo|
          i_profile = ipo.issuer_profile
          new_carrier_profile_map[ipo.hbx_id] = i_profile.id
        end

        service_area_map = {}
        ::BenefitMarkets::Locations::ServiceArea.all.map do |sa|
          service_area_map[[sa.issuer_profile_id,sa.issuer_provided_code,sa.active_year]] = sa.id
        end

        rating_area_id_cache = {}
        rating_area_cache = {}
        ::BenefitMarkets::Locations::RatingArea.all.each do |ra|
          rating_area_id_cache[[ra.active_year, ra.exchange_provided_code]] = ra.id
          rating_area_cache[ra.id] = ra
        end

        say_with_time("Migrate primary plan data") do
          Plan.all.each do |plan|
            premium_table_cache = Hash.new do |h, k|
              h[k] = Hash.new
            end
            plan.premium_tables.each do |pt|
              applicable_range = pt.start_on..pt.end_on
              rating_area_id = rating_area_id_cache[[plan.active_year, "R-DC001"]]
              premium_table_cache[[rating_area_id, applicable_range]][pt.age] = pt.cost
            end

            premium_tables = []
            premium_table_cache.each_pair do |k, v|
              rating_area_id, applicable_range = k
              premium_tuples = []
              v.each_pair do |pt_age, pt_cost|
                premium_tuples << ::BenefitMarkets::Products::PremiumTuple.new(
                  age: pt_age,
                  cost: pt_cost
                )
              end
              premium_tables << ::BenefitMarkets::Products::PremiumTable.new(
                effective_period: applicable_range,
                rating_area: rating_area_cache[rating_area_id],
                rating_area_id: rating_area_id,
                premium_tuples: premium_tuples
              )
            end

            product_kind = plan.coverage_kind
            issuer_profile_id = new_carrier_profile_map[old_carrier_profile_map[plan.carrier_profile_id]]
            mapped_service_area_id = service_area_map[[issuer_profile_id,"DCS001",plan.active_year]]
            shared_attributes = {
              benefit_market_kind: "aca_#{plan.market}",
              hbx_id: plan.hbx_id,
              title: plan.name,
              issuer_profile_id: issuer_profile_id,
              hios_id: plan.hios_id,
              hios_base_id: plan.hios_base_id,
              csr_variant_id: plan.csr_variant_id,
              application_period: (Date.new(plan.active_year, 1, 1)..Date.new(plan.active_year, 12, 31)),
              service_area_id: mapped_service_area_id,
              provider_directory_url: plan.provider_directory_url,
              sbc_document: plan.sbc_document,
              deductible: plan.deductible,
              family_deductible: plan.family_deductible,
              is_reference_plan_eligible: true,
              premium_ages: (plan.minimum_age..plan.maximum_age),
              premium_tables: premium_tables,
              issuer_assigned_id: plan.carrier_special_plan_identifier,
              nationwide: plan.nationwide,
              dc_in_network: plan.dc_in_network
            }
            # TODO Fix product_package_kinds for IVL products

            if product_kind.to_s.downcase == "health"
              product_package_kinds = [:metal_level, :single_issuer, :single_product]
              hp = BenefitMarkets::Products::HealthProducts::HealthProduct.new({
                health_plan_kind:  plan.plan_type? ? plan.plan_type.downcase : "hmo", # TODO 2014 plan issues, fix plan_type
                metal_level_kind: plan.metal_level,
                product_package_kinds: product_package_kinds,
                ehb: plan.ehb,
                is_standard_plan: plan.is_standard_plan,
                rx_formulary_url: plan.rx_formulary_url,
                hsa_eligibility: plan.hsa_eligibility,
                network_information: plan.network_information,
              }.merge(shared_attributes))
              if hp.valid?
                hp.save
              else
                raise "Health Product not saved #{hp.hios_id}."
              end
            else
              # TODO Fix product_package_kinds for IVL dentals if any
              dp = BenefitMarkets::Products::DentalProducts::DentalProduct.new({
                dental_plan_kind: plan.try(:plan_type).try(:downcase),  # TODO 2014 plan issues, fix plan_type
                metal_level_kind: :dental,
                ehb: plan.ehb,
                is_standard_plan: plan.is_standard_plan,
                hsa_eligibility: plan.hsa_eligibility,
                dental_level: plan.dental_level,
                product_package_kinds: [:multi_product, :single_issuer]
              }.merge(shared_attributes))
              if dp.valid?
                dp.save
              else
                raise "Dental Product not saved #{dp.hios_id}."
              end
            end
          end
        end

        say_with_time("Migrate catastrophic and renewal reference plan data") do
          products = BenefitMarkets::Products::Product.all
          products.each do |product|
            year = product.application_period.first.year
            plan = Plan.where(active_year: year, hios_id: product.hios_id).first

            renewal_plan_hios_id = plan.renewal_plan_id.present? ? plan.renewal_plan.hios_id : nil
            catastrophic_plan_hios_id = plan.cat_age_off_renewal_plan_id.present? ? plan.cat_age_off_renewal_plan.hios_id : nil

            renewal_product = if renewal_plan_hios_id.present?
              BenefitMarkets::Products::Product.where(hios_id: renewal_plan_hios_id).select{|product| product.application_period.first.year == plan.renewal_plan.active_year}.last
            else
              nil
            end

            catastrophic_product = if catastrophic_plan_hios_id.present?
              BenefitMarkets::Products::Product.where(hios_id: catastrophic_plan_hios_id).select{|product| product.application_period.first.year == plan.cat_age_off_renewal_plan.active_year}.last
            else
              nil
            end
            product.renewal_product = renewal_product
            product.catastrophic_age_off_product = catastrophic_product unless plan.coverage_kind == "dental"
            product.save
          end
          # Now that all the plans moved over, cross-map the catastropic, age-off,
          # and renewal plans from the original data
        end

        say_with_time("Create DC congress products") do
          products = BenefitMarkets::Products::Product.where(metal_level_kind: :gold, :benefit_market_kind => :aca_shop)
          products.each do |product|
            congress_product = product.deep_dup
            congress_product.benefit_market_kind = "fehb".to_sym
            congress_product._id = BSON::ObjectId.new
            congress_product.sbc_document._id = BSON::ObjectId.new if product.sbc_document.present?
            congress_product.premium_tables.map {|pt| pt._id = BSON::ObjectId.new}
            congress_product.premium_tables.each do |pt|
              pt.premium_tuples.map {|p_tuples| p_tuples._id = BSON::ObjectId.new}
            end
            if congress_product.valid?
              congress_product.save
            else
              raise "congress product not saved #{congress_product.hios_id}."
            end
          end
        end

      end
    else
      say "Skipping for non-DC site"
    end

  end

  def self.down
    if Settings.site.key.to_s == "dc"
      BenefitMarkets::Products::Product.all.delete_all
    else
      say("Skipping migration for non-DC site")
    end
  end
end