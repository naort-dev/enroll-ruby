require 'rails_helper'

RSpec.describe "insured/families/_terminate_confirmation.html.erb" do
  let(:hbx) { HbxEnrollment.new(hbx_id: 1) }
  before :each do
    render "insured/families/terminate_confirmation", enrollment: hbx
  end

  it "should prompt for the terminate reason" do
    expect(rendered).to have_selector('h4', text: /Select Terminate Reason/)
  end

  it "should have terminate reason options" do
    HbxEnrollment::WAIVER_REASONS.each do |w_reason|
      expect(rendered).to have_selector(:option, text: w_reason)
    end
  end

  it "should have disabled submit" do
    expect(rendered).to have_selector("input[disabled=disabled]", count: 1)
    expect(rendered).to have_selector("input[value='Submit']", count: 1)
  end

  context 'hidden field tags' do
    it 'should have hidden field terminate' do
      expect(rendered).to have_selector("input[name='terminate']", visible: false)
    end

    it 'should have hidden field change_plan' do
      expect(rendered).to have_selector("input[name='change_plan']", visible: false)
    end

    it 'should have hidden field hbx_enrollment_id' do
      expect(rendered).to have_selector("input[name='hbx_enrollment_id']", visible: false)
    end

    it 'should have hidden field terminate_date' do
      expect(rendered).to have_selector("input[name='terminate_date_#{hbx.hbx_id}']", visible: false)
    end
  end
end
