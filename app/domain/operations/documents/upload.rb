# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Operations
  module Documents
    class Upload
      send(:include, Dry::Monads[:result, :do, :try])

      include Config::SiteHelper

      def call(resource:, file_params:, user:)

        if resource.blank?
          return Failure({:message => ['Please find valid resource to create document.']})
        end

        header = yield construct_headers(resource, user)
        body = yield construct_body(resource, file_params)
        response = yield upload_to_doc_storage(resource, header, body)
        validated_params = yield validate_response(response.transform_keys(&:to_sym))
        file = yield create_document(resource, file_params, validated_params)
        Success(file)
      end

      private

      def encoded_payload(payload)
        Base64.strict_encode64(payload.to_json)
      end

      def fetch_file(file_params)
        file_params[:file].tempfile
      end

      def fetch_secret_key
        Rails.application.secrets.secret_key_base
      end

      def fetch_url
        Rails.application.config.cartafact_document_base_url
      end

      def construct_headers(resource, user)
        payload_to_encode = { "authorized_identity": {"user_id": user.id.to_s, "system": site_name},
                              "authorized_subjects": [{"type": "notice", "id": resource.id.to_s}] }

        Success({ 'HTTP-X-REQUESTINGIDENTITY' => encoded_payload(payload_to_encode),
                  'HTTP-X-REQUESTINGIDENTITYSIGNATURE' => Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", fetch_secret_key, encoded_payload(payload_to_encode)))
                })
      end

      def construct_body(resource, file_params)
        Success({ document: { subjects: [{"id": resource.id.to_s, "type": resource.class.to_s}], "document_type": 'notice', 'creator': Settings.site.publisher,
                              'publisher': Settings.site.publisher,
                              'type': 'text',
                              'format': 'application/octet-stream',
                              'source': 'enroll_system',
                              'language': 'en',
                              'date_submitted': TimeKeeper.date_of_record }.to_json,
                  content: fetch_file(file_params)
                })
      end

      def upload_to_doc_storage(resource, header, body)
        if Rails.env.production?
          response = HTTParty.post(fetch_url, :body => body, :headers => header)

          (response["errors"] || response["error"]).present? ? Failure({:message => ['Unable to upload document']}) : Success(response)
        else
          Success(test_env_response(resource))
        end
      end

      def validate_response(params)
        result = ::Validators::Documents::UploadContract.new.call(params)

        result.success? ? Success(result.to_h) : Failure(result.errors.to_h)
      end

      def create_document(resource, file_params, file_entity)
        Operations::Documents::Create.new.call(resource: resource, document_params: file_params, doc_identifier: file_entity[:id])
      end

      def test_env_response(resource)
        {"title"=>"untitled",
         "language"=>"en",
         "format"=>"application/octet-stream",
         "source"=>"enroll_system",
         "document_type"=>"notice",
         "subjects"=>[{"id"=>resource.id.to_s, "type"=>resource.class.to_s}],
         "id"=> BSON::ObjectId.new.to_s,
         "extension"=>"pdf"
         }
      end
    end
  end
end