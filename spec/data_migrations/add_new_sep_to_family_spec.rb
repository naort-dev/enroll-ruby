# frozen_string_literal: true

require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "add_new_sep_to_family")

describe AddNewSepToFamily, dbclean: :after_each do
  let(:given_task_name) { "add_new_sep_to_family" }
  subject { AddNewSepToFamily.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  def with_modified_env(options, &block)
    ClimateControl.modify(options, &block)
  end

  describe "creating a new sep" do
    let(:person) { FactoryBot.create(:person)}
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
    let!(:qle) { FactoryBot.create(:qualifying_life_event_kind, reason: 'open_enrollment_december_deadline_grace_period', effective_on_kinds: ["fixed_first_of_next_month"], market_kind: 'individual') }
    let!(:qle2) { FactoryBot.create(:qualifying_life_event_kind, reason: 'open_enrollment_december_deadline_grace_period', is_active: false, effective_on_kinds: ["fixed_first_of_next_month"], market_kind: 'individual') }

    let(:sep_params) { {sep_type: 'ivl', qle_reason: 'open_enrollment_december_deadline_grace_period', event_date: '12/28/2021', effective_date: '1/1/2022', sep_duration: '10', person_hbx_ids: person.hbx_id.to_s}}

    it "should create a new sep" do
      expect(person.primary_family.special_enrollment_periods.size).to eq 0
      ClimateControl.modify sep_params do
        subject.migrate
      end
      expect(person.primary_family.reload.special_enrollment_periods.size).to eq 1
      sep = person.primary_family.reload.special_enrollment_periods.last
      expect(sep.effective_on).to eq Date.strptime(sep_params[:effective_date], "%m/%d/%Y")
      expect(sep.qle_on).to eq Date.strptime(sep_params[:event_date], "%m/%d/%Y")
      expect(sep.start_on).to eq Date.strptime(sep_params[:event_date], "%m/%d/%Y")
      expect(sep.end_on).to eq(Date.strptime(sep_params[:event_date], "%m/%d/%Y") + sep_params[:sep_duration].to_i.days)
      expect(sep.qualifying_life_event_kind_id).to eq(qle.id)
    end
  end
end
