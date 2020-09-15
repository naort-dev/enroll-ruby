# frozen_string_literal: true

RSpec.describe Operations::FinancialAssistance::Apply, type: :model, dbclean: :after_each do
  let!(:person)        { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:person2)       { FactoryBot.create(:person, :with_consumer_role, :with_active_consumer_role) }
  let!(:family)        { FactoryBot.create(:family, :with_primary_family_member, person: person) }
  let!(:family_member) { FactoryBot.create(:family_member, family: family, person: person2) }
  let!(:hbx_profile)   { FactoryBot.create(:hbx_profile, :open_enrollment_coverage_period) }
  let(:product)        { FactoryBot.create(:benefit_markets_products_health_products_health_product, :ivl_product) }

  before :each do
    bcp = HbxProfile.current_hbx.benefit_sponsorship.current_benefit_coverage_period
    bcp.update_attributes!(slcsp_id: product.id)
  end

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'invalid arguments' do
    it 'should return a failure' do
      result = subject.call({family_id: 'family_id'})
      expect(result.failure).to eq('family_id is expected in BSON format')
    end
  end

  context 'with valid arguments' do
    it 'should return application id' do
      result = subject.call({family_id: family.id})
      expect(result.success.is_a?(BSON::ObjectId)).to be_truthy
    end
  end

end
