namespace :load_service_reference do

  task :run_all_service_areas => :environment do
    files = Dir.glob(File.join(Rails.root, "db/seedfiles/plan_xmls/#{Settings.aca.state_abbreviation.downcase}/xls_templates/service_areas/2019", "**", "*.xlsx"))
    puts "*"*80 unless Rails.env.test?
    CarrierServiceArea.delete_all # delete and recreate all carrier service areas.
    files.each do |file|
      puts "processing file #{file}" unless Rails.env.test?
      # old model
      Rake::Task['load_service_reference:update_service_areas'].invoke(file)
      Rake::Task['load_service_reference:update_service_areas'].reenable
      puts "created #{CarrierServiceArea.all.size} service areas in old model" unless Rails.env.test?
      # end old model

      # new model
      Rake::Task['load_service_reference:update_service_areas_new_model'].invoke(file)
      Rake::Task['load_service_reference:update_service_areas_new_model'].reenable
      # end new model
    end
    puts "*"*80 unless Rails.env.test?
  end

  task :update_service_areas_new_model, [:file] => :environment do |t,args|
    row_data_begin = 13
    @issuer_profile_hash = {}
    set_issuer_profile_hash
    count = 0
    begin
      file = args[:file]
      @year = file.split("/")[-2].to_i

      xlsx = Roo::Spreadsheet.open(file)
      sheet = xlsx.sheet(0)
      issuer_hios_id = sheet.cell(6,2).to_i.to_s
      (row_data_begin..sheet.last_row).each do |i|
        serves_entire_state = to_boolean(sheet.cell(i,3))
        serves_partial_county = to_boolean(to_boolean(sheet.cell(i,5)))
        if serves_entire_state
          ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
            active_year: @year,
            issuer_provided_code: sheet.cell(i,1),
            covered_states: ["MA"],
            issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
            issuer_provided_title: sheet.cell(i,2)
          })
          count+=1
        elsif serves_partial_county
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
          extracted_zips = extracted_zip_codes(sheet.cell(i,6)).each {|t| t.squish!}
          location_ids = ::BenefitMarkets::Locations::CountyZip.where({
            :zip.in => extracted_zips,
            county_name: county_name
          }).map(&:_id)

          sa = ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
            active_year: @year,
            issuer_provided_code: sheet.cell(i,1),
            issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
            issuer_provided_title: sheet.cell(i,2),
            county_zip_ids: location_ids.uniq
          })

          count+=1
        else
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
          location_ids = ::BenefitMarkets::Locations::CountyZip.where({
            county_name: county_name
          }).map(&:_id)

          ::BenefitMarkets::Locations::ServiceArea.find_or_create_by!({
            active_year: @year,
            issuer_provided_code: sheet.cell(i,1),
            issuer_profile_id: @issuer_profile_hash[issuer_hios_id],
            issuer_provided_title: sheet.cell(i,2),
            county_zip_ids: location_ids.uniq
          })

          count+=1
        end
      end

    rescue => e
      puts e.inspect unless Rails.env.test?
      puts " --------- " unless Rails.env.test?
      puts e.backtrace unless Rails.env.test?
    end
    puts "created #{count} service areas in new model" unless Rails.env.test?

  end

  desc "load service regions from xlsx file"
  task :update_service_areas, [:file] => :environment do |t,args|
    row_data_begin = 13
    count = 0
    begin
      file = args[:file]
      @year = file.split("/")[-2].to_i

      xlsx = Roo::Spreadsheet.open(file)
      sheet = xlsx.sheet(0)
      hios_id = sheet.cell(6,2).to_i
      (row_data_begin..sheet.last_row).each do |i|
        serves_entire_state = to_boolean(sheet.cell(i,3))
        serves_partial_county = to_boolean(to_boolean(sheet.cell(i,5)))

        if serves_entire_state
          CarrierServiceArea.create!(
            active_year: @year,
            issuer_hios_id: hios_id,
            service_area_id: sheet.cell(i,1),
            service_area_name: sheet.cell(i,2),
            serves_entire_state: true,
            county_name: nil,
            county_code: nil,
            state_code: nil,
            service_area_zipcode: nil,
            partial_county_justification: nil
          )
          count = count + 1
        elsif serves_partial_county
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
          extracted_zip_codes(sheet.cell(i,6)).each do |zip|
            CarrierServiceArea.create!(
              active_year: @year,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: false,
              county_name: county_name,
              county_code: county_code,
              state_code: state_code,
              service_area_zipcode: zip,
              partial_county_justification: sheet.cell(i,7)
            )
            count = count + 1
          end
        else
          county_name, state_code, county_code = extract_county_name_state_and_county_codes(sheet.cell(i,4))
            RatingArea.find_zip_codes_for(county_name: county_name).each do |zip|
              CarrierServiceArea.create!(
              active_year: @year,
              issuer_hios_id: hios_id,
              service_area_id: sheet.cell(i,1),
              service_area_name: sheet.cell(i,2),
              serves_entire_state: false,
              county_name: county_name,
              county_code: county_code,
              state_code: state_code,
              service_area_zipcode: zip,
              partial_county_justification: nil
            )
            count = count + 1
          end
        end
      end
    rescue => e
      puts e.inspect unless Rails.env.test?
      puts " --------- " unless Rails.env.test?
      puts e.backtrace unless Rails.env.test?
    end

  end

  private

  def set_issuer_profile_hash
    exempt_organizations = ::BenefitSponsors::Organizations::Organization.issuer_profiles
    exempt_organizations.each do |exempt_organization|
      issuer_profile = exempt_organization.issuer_profile
      issuer_profile.issuer_hios_ids.join.split(",").each do |issuer_hios_id|
        @issuer_profile_hash[issuer_hios_id] = issuer_profile.id.to_s
      end
    end
    @issuer_profile_hash
  end

  def to_boolean(value)
    return true   if value == true   || value =~ (/(true|t|yes|y|1)$/i)
    return false  if value == false  || value =~ (/(false|f|no|n|0)$/i)
    return nil
  end

  def extracted_zip_codes(column)
    column.split(/\s*,\s*/)
  end

  def extract_county_name_state_and_county_codes(county_field)
    begin
      county_name, state_and_county_code = county_field.split(' - ')
      [county_name, state_and_county_code[0..1], state_and_county_code[2..state_and_county_code.length]]
    rescue => e
      puts county_field
      puts e.inspect
      return ['undefined',nil,nil]
    end
  end

end
