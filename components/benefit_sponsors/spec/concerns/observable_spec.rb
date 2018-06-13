require 'rails_helper'

shared_examples_for "observable" do
  let(:model) { create described_class.to_s.underscore.gsub('/', '_').to_sym }

  before do
    allow(model).to receive(:notify_observers)
    model.touch
    model.save
  end

  it 'calls notify_observers after update' do
    expect(model).to have_received(:notify_observers)
  end
end
