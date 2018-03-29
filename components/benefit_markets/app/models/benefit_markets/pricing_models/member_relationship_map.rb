module BenefitMarkets
  module PricingModels
    class MemberRelationshipMap
      include Mongoid::Document
      include Mongoid::Timestamps

      embedded_in :pricing_unit, inverse_of: :member_relationship_maps

      field :relationship_name, type: Symbol
      field :operator, type: Symbol, default: :==
      field :count, type: Integer

      validates_presence_of :relationship_name, allow_blank: false
      validates_numericality_of :count, allow_blank: false
      validates_inclusion_of :operator, in: [:>=, :<=, :==, :<, :>]

      validate :has_mappable_relationship

      def has_mappable_relationship
        if display_relationship_name.blank?
          errors.add(:relationship_name, "does not match a member relationship in the contribution model")
        end
      end

      def display_relationship_name
        @member_relationship ||= search_member_relationships
      end

      protected

      def search_member_relationships
        return nil if pricing_unit.blank?
        return nil if pricing_unit.pricing_model.blank?
        return nil if pricing_unit.pricing_model.member_relationships.blank?
        pricing_unit.pricing_model.member_relationships.detect do |mrel|
          mrel.relationship_name == relationship_name
        end
      end
    end
  end
end
