# frozen_string_literal: true

module Eligibilities
  # Use Visitor Development Pattern to access Eligibilities and Eveidences
  # distributed across models
  class EligibilityItem
    include Mongoid::Document
    include Mongoid::Timestamps

    embeds_many :evidence_items

    field :key, type: Symbol
    field :title, type: String
    field :description, type: String
    field :tags, type: Array
    field :published_at, type: DateTime

  end
end
