require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'creating_person_record')

describe CreatingPersonRecord, dbclean: :after_each do
  let(:given_task_name) { 'creating_person_record' }
  subject { CreatingPersonRecord.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'should create Person record' do
    it 'should create person record' do
      ClimateControl.modify file_name: 'spec/test_data/person_test_record.csv' do
        expect(Person.all.to_a.size).to eq 0 # before migration
        subject.migrate
        expect(Person.all.to_a.size).to eq 1 # after migration
      end
    end
  end
end
