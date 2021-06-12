# frozen_string_literal: true

require 'rails_helper'
require "#{FinancialAssistance::Engine.root}/spec/shared_examples/medicaid_gateway/test_case_d_response"

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::AddEligibilityDetermination, dbclean: :after_each do
  before :all do
    DatabaseCleaner.clean
  end

  let!(:application) do
    FactoryBot.create(:financial_assistance_application, hbx_id: response_payload[:hbx_id])
  end
  let!(:ed) do
    eli_d = FactoryBot.create(:financial_assistance_eligibility_determination, application: application)
    eli_d.update_attributes!(hbx_assigned_id: '12345')
    eli_d
  end
  let!(:applicant) do
    FactoryBot.create(:financial_assistance_applicant,
                      eligibility_determination_id: ed.id,
                      person_hbx_id: '95',
                      first_name: 'Gerald',
                      last_name: 'Rivers',
                      dob: Date.new(current_date.year - 22, current_date.month, current_date.day),
                      application: application)
  end

  context 'cms_ME_simple_scenarios test_case_d' do
    include_context 'cms ME simple_scenarios test_case_d'

    before do
      @result = subject.call(response_payload)
      @application = ::FinancialAssistance::Application.by_hbx_id(response_payload[:hbx_id]).first.reload
      @ed = @application.eligibility_determinations.first
      @applicant = @ed.applicants.first
    end

    it 'should return success' do
      expect(@result).to be_success
    end

    it 'should return success with a message' do
      expect(@result.success).to eq('Successfully updated Application object with Full Eligibility Determination')
    end

    context 'for Eligibility Determination' do
      it 'should update max_aptc' do
        expect(@ed.max_aptc.to_f).to eq(496.0)
      end

      it 'should update is_eligibility_determined' do
        expect(@ed.is_eligibility_determined).to eq(true)
      end

      it 'should update source' do
        expect(@ed.source).to eq('Faa')
      end
    end

    context 'for Applicant' do
      it 'should update is_ia_eligible' do
        expect(@applicant.is_ia_eligible).to eq(true)
      end

      it 'should update is_medicaid_chip_eligible' do
        expect(@applicant.is_medicaid_chip_eligible).to eq(false)
      end

      it 'should update is_non_magi_medicaid_eligible' do
        expect(@applicant.is_non_magi_medicaid_eligible).to eq(false)
      end
    end
  end
end
