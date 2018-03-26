# Attributes, validations and constraints common to all Profile classes embedded in an Organization
module BenefitSponsors
  module Organizations
    class Profile
      include Mongoid::Document
      include Mongoid::Timestamps

      PROFILE_SOURCE_KINDS = [:broker_quote]

      embedded_in :organization,      class_name: "BenefitSponsors::Organizations::Organization"

      field :contact_method,          type: Symbol, default: :paper_and_electronic

      # Terminated twice for non-payment?
      field :is_benefit_sponsorship_eligible,  type: Boolean, default: false
      field :benefit_sponsorship_id,        type: BSON::ObjectId

      # Share common attributes across all Profile kinds
      delegate :hbx_id,                   to: :organization, allow_nil: false
      delegate :legal_name, :legal_name=, to: :organization, allow_nil: false
      delegate :dba, :dba=,               to: :organization, allow_nil: true
      delegate :fein, :fein=,             to: :organization, allow_nil: true
      delegate :updated_by, :updated_by=, to: :organization, allow_nil: false

      embeds_many :office_locations, 
                  class_name:"BenefitSponsors::Locations::OfficeLocation"

      alias_method :is_benefit_sponsorship_eligible?, :is_benefit_sponsorship_eligible

      # @abstract profile subclass is expected to implement #initialize_profile
      # @!method initialize_profile
      #    Initialize settings for the abstract profile
      after_initialize :initialize_profile


      def benefit_sponsorship
        return @benefit_sponsorship if defined?(@benefit_sponsorship)
        @benefit_sponsorship = organization.benefit_sponsorships.detect { |benefit_sponsorship| benefit_sponsorship._id == self.benefit_sponsorship_id }
      end

      def benefit_sponsorship=(benefit_sponsorship)
        write_attribute(:benefit_sponsorship_id, benefit_sponsorship._id)
        @benefit_sponsorship = benefit_sponsorship
      end

    end
  end
end
