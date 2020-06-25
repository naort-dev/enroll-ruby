# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module SecureMessages
    class Create
      include Config::SiteConcern
      send(:include, Dry::Monads[:result, :do])

      def call(params)
        payload = yield construct_message_payload(params[:message_params])
        validated_payload = yield validate_message_payload(payload)
        message_entity = yield create_message_entity(validated_payload)
        resource = yield create(params[:resource], message_entity.to_h)

        Success(resource)
      end

      private

      def construct_message_payload(message_params)
        Success(message_params.merge!(from: site_short_name))
      end

      def validate_message_payload(params)
        result = ::Validators::SecureMessages::MessageContract.new.call(params)
        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def create_message_entity(params)
        message = ::Entities::SecureMessages::Message.new(params)
        Success(message)
      end

      def create(resource, message_entity)
        resource.inbox.messages << Message.new(message_entity)
        resource.save!
        Success(resource)
      end

    end
  end
end
