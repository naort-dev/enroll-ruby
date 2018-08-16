require File.join(Rails.root, "lib/mongoid_migration_task")

class LoadIssuerProfiles < MongoidMigrationTask

  def migrate
    issuer_profile_data = [
      {fein: "043373331", legal_name: "BMC HealthNet Plan", abbreviation: "BMCHP", hbx_carrier_id: 20003, issuer_hios_ids: "82569", shop_health: true },
      {fein: "237442369", legal_name: "Fallon Health", abbreviation: "FCHP", hbx_carrier_id: 20005, issuer_hios_ids: "88806", shop_health: true },
      {fein: "042864973", legal_name: "Health New England", abbreviation: "HNE", hbx_carrier_id: 20007, issuer_hios_ids: "34484", shop_health: true },
      {fein: "041045815", legal_name: "Blue Cross Blue Shield MA", abbreviation: "BCBS", hbx_carrier_id: 20002, issuer_hios_ids: "42690", shop_health: true },
      {fein: "042452600", legal_name: "Harvard Pilgrim Health Care", abbreviation: "HPHC", hbx_carrier_id: 20008, issuer_hios_ids: "36046", shop_health: true },
      {fein: "234547586", legal_name: "Neighborhood Health Plan", abbreviation: "NHP", hbx_carrier_id: 20010, issuer_hios_ids: "41304", shop_health: true },
      {fein: "800721489", legal_name: "Tufts Health Direct", abbreviation: "THPD", hbx_carrier_id: 20011, issuer_hios_ids: "59763", shop_health: true },

      {fein: "362739571", legal_name: "UnitedHealthcare", abbreviation: "UHIC", hbx_carrier_id: 20014, issuer_hios_ids: "31779", shop_health: true },
      # {fein: "050513223", legal_name: "Altus", abbreviation: "ALT", hbx_carrier_id: 20001, issuer_hios_ids: "18076", shop_dental: true },
      # {fein: "046143185", legal_name: "Delta Dental", abbreviation: "DDA", hbx_carrier_id: 20004, issuer_hios_ids: "80538,11821", shop_dental: true }
    ]

    site_key = "cca"
    site = BenefitSponsors::Site.all.where(site_key: site_key.to_sym).first

    puts "*"*80 unless Rails.env.test?
    issuer_profile_data.each do |issuer_profile|

      fein = issuer_profile[:fein]
      legal_name = issuer_profile[:legal_name]
      abbreviation = issuer_profile[:abbreviation]
      hbx_carrier_id = issuer_profile[:hbx_carrier_id]
      issuer_hios_ids = issuer_profile[:issuer_hios_ids]
      ivl_health = issuer_profile[:ivl_health].present? ? true : false
      ivl_dental = issuer_profile[:ivl_dental].present? ? true : false
      shop_health = issuer_profile[:shop_health].present? ? true : false
      shop_dental = issuer_profile[:shop_dental].present? ? true : false

      exempt_organiation_params = {
        fein: fein,
        site_id: site.id,
        legal_name: legal_name
      }

      exempt_organization = BenefitSponsors::Organizations::ExemptOrganization.where(:"profiles.hbx_carrier_id" => hbx_carrier_id).first
      new_exempt_organization = if exempt_organization.present?
        exempt_organization
      else
        BenefitSponsors::Organizations::ExemptOrganization.new(exempt_organiation_params)
      end

      issuer_profile = new_exempt_organization.profiles.first
      if issuer_profile.present?
        puts "Carrier #{legal_name} already exists with this hbx_carrier_id #{hbx_carrier_id}." unless Rails.env.test?
      else
        office_location = BenefitSponsors::Locations::OfficeLocation.new(
          is_primary: true,
          address: {kind: "work", address_1: "address_placeholder", address_2: "address_2", city: "City", state: "St", zip: "10001" },
          phone: {kind: "main", area_code: "111", number: "111-1111"}
        )

        issuer_profile_params = {
          hbx_carrier_id: hbx_carrier_id,
          abbrev: abbreviation,
          ivl_health: ivl_health,
          ivl_dental: ivl_dental,
          shop_health: shop_health,
          shop_dental: shop_dental,
          issuer_hios_ids: [issuer_hios_ids],
          office_locations: [office_location],
        }

        new_issuer_profile = BenefitSponsors::Organizations::IssuerProfile.new(issuer_profile_params)

        new_exempt_organization.profiles << new_issuer_profile
        new_exempt_organization.save

        puts "Successfully created #{legal_name} carrier." unless Rails.env.test?
      end
    end
    puts "*"*80 unless Rails.env.test?
  end

end