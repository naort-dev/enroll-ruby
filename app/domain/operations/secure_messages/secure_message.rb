# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module SecureMessages
    class SecureMessage
      send(:include, Dry::Monads[:result, :do, :try])

      def call(params:)
        validate_params = yield validate_params(params)
        resource = yield fetch_resource(validate_params)
        result = yield upload_secure_message(resource, validate_params)

        Success(result)
      end

      private

      def validate_params(params)
        result = ::Validators::SecureMessages::SecureMessageContract.new.call(params)

        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def fetch_resource(validate_params)
        if validate_params[:profile_id].present?
          BenefitSponsors::Operations::Profiles::FindProfile.new.call(profile_id: validate_params[:profile_id])
        end
      end

      def upload_secure_message(resource, params)
        ::Operations::SecureMessages::Create.new.call(resource: resource, message_params: params)
      end

    end
  end
end
