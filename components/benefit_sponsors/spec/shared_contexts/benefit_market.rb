RSpec.shared_context "setup benefit market with market catalogs and product packages", :shared_context => :metadata do
  
  let(:renewal_effective_date)  { (TimeKeeper.date_of_record + 2.months).beginning_of_month }
  let(:current_effective_date)  { renewal_effective_date.prev_year }
  let(:effective_period)        { current_effective_date..current_effective_date.next_year.prev_day }

  let(:benefit_market)          { create(:benefit_markets_benefit_market, site_urn: 'mhc', kind: :aca_shop, title: "MA Health Connector SHOP Market") }

  let!(:current_benefit_market_catalog) { build(:benefit_markets_benefit_market_catalog, :with_product_packages,
    benefit_market: benefit_market,
    title: "SHOP Benefits for #{current_effective_date.year}",
    application_period: (current_effective_date.beginning_of_year..current_effective_date.end_of_year))
  }

  let!(:renewal_benefit_market_catalog) { build(:benefit_markets_benefit_market_catalog, :with_product_packages,
    benefit_market: benefit_market,
    title: "SHOP Benefits for #{renewal_effective_date.year}",
    application_period: (renewal_effective_date.beginning_of_year..renewal_effective_date.end_of_year))
  }

  before do 
    map_products
  end

  def map_products
    current_benefit_market_catalog.product_packages.each do |product_package|
      if renewal_product_package = renewal_benefit_market_catalog.product_packages.detect{ |p|
        p.package_kind == product_package.package_kind && p.product_kind == product_package.product_kind }

        renewal_product_package.products.each_with_index do |renewal_product, i|
          current_product = product_package.products[i]
          current_product.update(renewal_product_id: renewal_product.id)
        end
      end
    end
  end

  it "should create valid benefit market catalogs" do
    expect(current_benefit_market_catalog).to be_valid
    expect(renewal_benefit_market_catalog).to be_valid
  end
end