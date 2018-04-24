require 'date'
module BenefitSponsors
  module Organizations
    module Factories
      class ProfileFactory
        include ActiveModel::Validations
        include BenefitSponsors::Forms::NpnField

        attr_accessor :profile_id, :profile_type, :organization, :current_user, :claimed, :pending
        attr_accessor :first_name, :last_name, :email, :dob, :npn, :fein, :legal_name, :person, :entity_kind, :market_kind
        attr_accessor :area_code, :number, :extension

        validate :validate_duplicate_npn, if: :is_broker_profile?
        validate :office_location_kinds

        def validate_duplicate_npn
          if Person.where("broker_role.npn" => npn).any?
            errors.add(:organization, "NPN has already been claimed by another broker. Please contact HBX-Customer Service - Call (855) 532-5465.")
          end
        end

        def office_location_kinds
          location_groups = organization.profiles.map(&:office_locations)
          location_groups.each do |locations|
            location_kinds = locations.flat_map(&:address).flat_map(&:kind)
            if location_kinds.count('primary').zero?
              self.errors.add(:office_locations, "must select one primary address")
            elsif location_kinds.count('primary') > 1
              self.errors.add(:office_locations, "can't have multiple primary addresses")
            elsif location_kinds.count('mailing') > 1
              self.errors.add(:office_locations, "can't have more than one mailing address")
            end
          end
        end

        def self.call_persist(attributes)
          factory_obj = new(attributes)
          factory_obj.current_user = current_user(attributes[:current_user_id])
          factory_obj.save(attributes[:organization])
        end

        def self.call_update(attributes)
          factory_obj = new(attributes)
          organization = factory_obj.get_organization
          organization.update_attributes(attributes[:organization])
        end

        def self.build(attrs)
          new(attrs).build_organization
        end

        def initialize(attrs)
          self.profile_type = attrs[:profile_type]
          self.profile_id = attrs[:profile_id]
          initialize_attributes(attrs)
        end

        def initialize_attributes(attrs)
          initialize_staff_role_attributes(staff_role_attributes(attrs[:staff_roles_attributes])) # Always one while creating
          initialize_agency_attributes(attrs[:organization])
        end

        def initialize_staff_role_attributes(attrs)
          if attrs.present?
            self.first_name = attrs[:first_name]
            self.last_name = attrs[:last_name]
            self.email = attrs[:email]
            self.dob = attrs[:dob]
            self.npn = attrs[:npn]
            self.area_code = attrs[:area_code]
            self.number = attrs[:number]
            self.extension = attrs[:extension]
          end
        end

        def initialize_agency_attributes(attrs)
          if attrs.present?
            self.fein = attrs[:fein]
            self.legal_name = attrs[:legal_name]
          end
        end

        def save(attributes)
          return false, redirection_url, errors.full_messages unless match_or_create_person
          existing_org = get_existing_organization
          return false, redirection_url, errors.full_messages if failed_validity?(existing_org)
          self.organization = init_profile_organization(existing_org, attributes)
          return false, redirection_url, errors.full_messages unless persist_agency!
          [true, redirection_url(pending, true)]
        end

        def persist_agency!
          if organization.valid?
            organization.save!
            persist_representative!
          else
            errors.add(:organization, organization.errors.full_messages)
            return false
          end
          return true
        end

        def persist_representative!
          if is_broker_profile?
            persist_broker_staff_role!(organization.broker_agency_profile)
          elsif is_employer_profile?
            persist_employer_staff_role!(organization.employer_profile, claimed)
          end
        end

        def persist_broker_staff_role!(profile)
          person.broker_role = ::BrokerRole.new({
            :provider_kind => 'broker',
            :npn => self.npn,
            :broker_agency_profile_id => profile.id,
            :market_kind => market_kind
          })

          profile.office_locations.each do  |office_location|
            self.person.phones.push(Phone.new(office_location.phone.attributes.except("_id")))
          end
          person.save!
          trigger_broker_application_confirmation_email
        end

        def persist_employer_staff_role!(profile, existing_company)
          person.user = current_user
          employer_ids = person.employer_staff_roles.map(&:employer_profile_id)
          if employer_ids.include? profile.id
            pending = false
          else
            pending = existing_company && Person.staff_for_employer(profile).detect{|person|person.user_id}
            role_state = pending ? 'is_applicant' : 'is_active' 
            person.employer_staff_roles << EmployerStaffRole.new(person: person, :employer_profile_id => profile.id, is_owner: true, aasm_state: role_state)
          end
          self.pending = pending
          current_user.roles << "employer_staff" unless current_user.roles.include?("employer_staff")
          current_user.save!
          person.save!
        end

        def init_profile_organization(existing_org, attributes)
          if is_broker_profile?
            init_broker_organization(existing_org, attributes)
          elsif is_employer_profile?
            init_benefit_organization(existing_org, attributes)
          end
        end

        def init_broker_organization(organization, attributes)
          if organization.present? && !organization.broker_agency_profile.present?
            organization.profiles << build_profile(profile_attributes(attributes))
            organization
          else
            build_organization(attributes)
          end
        end

        def init_benefit_organization(existing_org, attributes)
          if existing_org
            self.claimed = is_employer_profile_claimed?(existing_org)
            unless claimed
              if existing_org.employer_profile.blank?
                existing_org.profiles << build_profile(profile_attributes(attributes))
              end
            end
            existing_org
          else
            build_organization(attributes)
          end
        end

        def build_organization(attrs = {})
          if profile_id.blank?
            self.organization = build_organization_class.new(organization_attributes(attrs))
            self.organization.profiles << build_profile(profile_attributes(attrs))
            self.organization
          else
            get_organization
          end
        end

        def build_profile(attrs = {})
          profile = if is_broker_profile?
                      build_broker_profile(attrs)
                    elsif is_employer_profile?
                      build_sponsor_profile(attrs)
                    end
          profile.office_locations << build_office_locations if profile.office_locations.empty?
          profile
        end

        def build_office_locations
          new_office_location = Locations::OfficeLocation.new
          new_office_location.build_address
          new_office_location.build_phone
          new_office_location
        end

        def build_broker_profile(attrs = {})
          Organizations::BrokerAgencyProfile.new(attrs)
        end

        def build_sponsor_profile(attrs = {})
          build_sponsor_profile_class.new(attrs)
        end

        def build_sponsor_profile_class
          if site_key == :dc
            Organizations::AcaShopDcEmployerProfile
          elsif site_key == :cca
            Organizations::AcaShopCcaEmployerProfile
          end
        end

        def build_organization_class
          # Use GeneralOrganization for now
          GeneralOrganization || ExemptOrganization
        end

        def build_person
          Person.new({
            :first_name => first_name.strip,
            :last_name => last_name.strip,
            :dob => dob
          })
        end

        def get_organization
          self.organization = build_organization_class.where(:"profiles._id" => BSON::ObjectId.from_string(profile_id)).first
        end

        def organization_attributes(attrs = {})
          attrs.except(:profiles_attributes).merge({
            site: site,
            fein: (fein.present? ? fein.strip : nil),
            legal_name: (legal_name.present? ? legal_name.strip : nil)
          })
        end

        def profile_attributes(attrs={})
          attrs[:profiles_attributes][0] if attrs[:profiles_attributes].present?
        end

        def staff_role_attributes(attrs={})
          attrs.present? ? attrs[0] : attrs
        end

        def match_or_create_person

          matched_people = get_matched_people

          if matched_people.count > 1
            errors.add(:staff_role, "too many people match the criteria provided for your identity.  Please contact HBX.")
            return false
          end

          if matched_people.count == 1
            mp = matched_people.first
            if is_employer_profile? && mp.user.present?
              if mp.user.id.to_s != current_user.id
                errors.add(:staff_role, "a person matching the provided personal information has already been claimed by another user.  Please contact HBX.")
                return false
              end
            end
            self.person = mp
          else
            self.person = build_person
          end

          add_person_contact_info
          person.save!
        end

        def failed_validity?(org)
          issuer_requesting_sponsor_benefits?(org) || broker_profile_already_registered?(org) || person.errors.present?
        end

        def is_employer_profile_claimed?(organization)
          if organization.present?
            if organization.employer_profile.present?
              if (Person.where({"employer_staff_roles.employer_profile_id" => organization.employer_profile._id}).any?)
                return true
              end
            end
          end
        end

        def broker_profile_already_registered?(organization)
          if is_broker_profile?
            organization.present? && organization.broker_agency_profile.present?
            errors.add(:organization, "has already been created for this Agency type")
            return true
          end
          return false
        end

        def issuer_requesting_sponsor_benefits?(organization)
          if organization.present? && organization.is_an_issuer_profile?
            errors.add(:organization, "Issuer cannot sponsor benefits")
            return true
          end
        end

        def redirection_url(is_pending=nil, is_saved=nil)
          if is_broker_profile?
            :broker_new_registration_url
          elsif is_employer_profile?
            return :sponsor_show_pending_registration_url if is_pending
            return :sponsor_home_registration_url if is_saved
            :sponsor_new_registration_url
          end
        end

        def trigger_broker_application_confirmation_email
          ::UserMailer.broker_application_confirmation(person).deliver_now
        end

        protected

        def site
          BenefitSponsors::ApplicationController::current_site
        end

        def site_key
          site.site_key
        end

        def is_broker_profile?
          profile_type == "broker_agency"
        end

        def is_employer_profile?
          profile_type == "benefit_sponsor"
        end

        def regex_for(str)
          clean_string = Regexp.escape(str.strip)
          /^#{clean_string}$/i
        end

        def add_person_contact_info
          if is_broker_profile?
            person.add_work_email(email)
          elsif is_employer_profile?
            person.contact_info(email, area_code, number, extension) if email
          end
        end

        def get_matched_people
          if is_employer_profile? || is_broker_profile?
            Person.where(
              first_name: regex_for(first_name),
              last_name: regex_for(last_name),
              dob: dob
              )
          else
            Person.where(
              first_name: regex_for(first_name),
              last_name: regex_for(last_name)
            )
          end
        end

        def get_existing_organization
          Organization.where(:fein => fein).first
        end

        def self.current_user(user_id)
          if user_id.present?
            User.find(user_id)
          end
        end

        def self.broker_agency_profile(profile_id)
          organization = BenefitSponsors::Organizations::Organization.where(:"profiles._id" => BSON::ObjectId.from_string(profile_id)).first
          organization.broker_agency_profile.present? ? organization.broker_agency_profile : nil
        end

        def self.find_representatives(profile_id)
          return [Person.new] if profile_id.blank?
          # Should handle the case where Org having both profiles
          broker_agency = broker_agency_profile(profile_id[:profile_id])

          if broker_agency.present?
            [broker_agency.primary_broker_role.person]
          else
            Person.where(:benefit_sponsors_employer_staff_roles => {
              '$elemMatch' => {
                employer_profile_id: profile_id,
                :aasm_state.ne => :is_closed
              }
            })
          end
        end
      end
    end
  end
end
