module BenefitSponsors
  module Serializers
    class OfficeLocationSerializer < ActiveModel::Serializer
      attributes :is_primary, :id
      attribute :id, if: :is_persisted?

      has_one :phone
      has_one :address

      def is_persisted?
        object.persisted?
      end

      # provide defaults(if any needed) that were not set on Model
      def attributes(*args)
        hash = super
        unless object.persisted?

        end
        hash
      end
    end
  end
end
