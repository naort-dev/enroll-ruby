# frozen_string_literal: true

require 'rails_helper'

describe SeedRowWorker, :dbclean => :after_each do
  describe "#perform" do
    let(:file_location) do
      filename = "#{Rails.root}/ivl_testbed_scenarios_*.csv"
      ivl_testbed_templates = Dir.glob(filename)
      ivl_testbed_templates.first
    end
    let(:user) { FactoryBot.create(:user) }

    before do
      @seed = Seeds::Seed.new(
        user: user,
        filename: file_location, # Get filename
        aasm_state: 'draft'
      )
      # TODO: need to figure out how to save the file
      CSV.foreach(file_location, headers: true) do |row|
        # To avoid nil values
        row_data = row.to_h.reject { |key, _value| key.blank? }.transform_values { |v| v.blank? ? "" : v }.with_indifferent_access
        @seed.rows.build(data: row_data)
      end
      @seed.save!
    end

    it "should be able to seed the database and infer data like primary families/persons" do
      # To speed up only do a few of them
      @seed.rows.to_a[0..5].each do |seed_row|
        SeedRowWorker.new.perform(seed_row.id, @seed.id)
      end
      expect(FinancialAssistance::Application.all.count).to be > 0 if EnrollRegistry.feature_enabled?(:financial_assistance)
      expect(Family.all.count).to be > 0
      expect(HbxEnrollment.all.count).to be > 0
    end
  end
end
