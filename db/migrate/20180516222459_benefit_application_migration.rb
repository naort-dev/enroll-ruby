class BenefitApplicationMigration < Mongoid::Migration

  def self.up
    # site_key = "dc"
    # Dir.mkdir("hbx_report") unless File.exists?("hbx_report")
    # file_name = "#{Rails.root}/hbx_report/benefit_application_status#{TimeKeeper.datetime_of_record.strftime("%m_%d_%Y_%H_%M_%S")}.csv"
    # field_names = %w(organization_name organization_fein plan_year_start_on status)
    # logger = Logger.new("#{Rails.root}/log/benefit_application_migration.log")
    # logger.info "Script Start - #{TimeKeeper.datetime_of_record}" unless Rails.env.test?
    # CSV.open(file_name, 'w') do |csv|
    #   csv << field_names
    #   status = migrate_plan_years_to_benefit_applications(site_key, csv, logger)
    #   if status
    #     puts "Check the report and logs for futher information"
    #   else
    #     puts "Data migration failed"
    #   end
    # end
  end

  def self.down
  end

  class BenefitSponsorshipMigrationService
    def self.fetch_sponsorship_for(new_organization, plan_year)
      self.new(new_organization, plan_year).benefit_sponsorship
    end

    def initialize(new_organization, plan_year)
      find_or_create_benefit_sponsorship(new_organization, plan_year)
    end

    def find_or_create_benefit_sponsorship(old_organization, new_organization, plan_year)
      @benefit_sponsorship = benefit_sponsorship_for(new_organization, plan_year.start_on)

      if @benefit_sponsorship.blank?
        create_new_benefit_sponsorship(new_organization, plan_year)
      end

      if is_plan_year_effectuated?(plan_year)
        if [:active, :suspended, :terminated, :ineligible].exclude?(@benefit_sponsorship.aasm_state)
          effectuate_benefit_sponsorship(plan_year)
        end

        if has_no_successor_plan_year?(plan_year)
          @benefit_sponsorship.terminate_enrollment(plan_year.terminated_on || plan_year.end_on)
        end
      end
    end

    def benefit_sponsorship_for(new_organization, plan_year_start)
      benefit_sponsorship = new_organization.benefit_sponsorships.desc(:effective_begin_on).effective_begin_on(plan_year_start).first

      if benefit_sponsorship && benefit_sponsorship.effective_end_on.present?
        (benefit_sponsorship.effective_end_on > plan_year_start) ? benefit_sponsorship : nil
      else
        benefit_sponsorship
      end
    end

    # Add proper state transitions to benefit sponsorship
    def effectuate_benefit_sponsorship(plan_year)
      @benefit_sponsorship
    end

    def create_new_benefit_sponsorship(new_organization, plan_year)
      @benefit_sponsorship
    end

    def is_plan_year_effectuated?(plan_year)
      %w(active suspended expired terminated termination_pending).include?(plan_year.aasm_state)
    end

    def has_no_successor_plan_year?(plan_year)
      other_plan_years = plan_year.employer_profile.plan_years

      if plan_year.end_on > TimeKeeper.datetime_of_record
        true
      else
        other_plan_years.any?{|py| py != plan_year && py.start_on == plan_year.end_on.next_day && is_a_effectuated_plan_year?(py) }
      end
    end

    def benefit_sponsorship
      @benefit_sponsorship
    end

    def benefit_market
      site.benefit_market_for(:aca_shop)
    end

    def self.find_site(site_key)
      BenefitSponsors::Site.all.where(site_key: site_key.to_sym)
    end

    # check if organization has continuous coverage
    def has_continuous_coverage_previously?(org)
      true
    end
  end

  private

  def migrate_plan_years_to_benefit_applications(site_key, csv, logger)
    say_with_time("Time taken to pull all old organizations with plan years") do
      old_organizations = Organization.unscoped.exists(:"employer_profile.plan_years" => true)
    end

    success = 0
    failed  = 0
    limit   = 100

    say_with_time("Time take to migrate plan years") do
      old_organizations.batch_size(limit).no_timeout.each do |old_org|
        new_organization = new_org(old_org)
        next unless new_organization.present?

        old_org.employer_profile.plan_years.asc(:start_on).each do |plan_year|
          begin
            benefit_sponsorship = BenefitSponsorshipMigrationService.fetch_sponsorship_for(new_organization, plan_year)
            benefit_application = contruct_benefit_application(benefit_sponsorship, plan_year)

            if benefit_application.valid?
              benefit_application.save!
              csv << [old_org.legal_name, old_org.fein, plan_year.start_on, 'Success']
              success += 1
            else
              raise StandardError, benefit_application.errors.to_s
            end
          rescue Exception => e
            csv << [old_org.legal_name, old_org.fein, plan_year.start_on, 'Failed', e.to_s]
            failed += 1
          end
        end
      end

      logger.info " Total #{total_organizations} old organizations with plan years" unless Rails.env.test?
      logger.info " #{failed} plan years failed to migrate into new DB at this point." unless Rails.env.test?
      logger.info " #{success} plan years successfully migrated into new DB at this point." unless Rails.env.test?
    end
  end

  def construct_benefit_application(benefit_sponsorship, plan_year)
    benefit_application = construct_benefit_application(benefit_sponsorship, plan_year)

    py_attrs = plan_year.attributes.except(:benefit_groups, :workflow_state_transitions)
    application_attrs = py_attrs.slice(:fte_count, :pte_count, :msp_count, :enrolled_summary, :waived_summary, :created_at, :updated_at, :terminated_on)

    benefit_application = benefit_sponsorship.benefit_applications.new(application_attrs)
    benefit_application.effective_period = (plan_year.start_on..plan_year.end_on)
    benefit_application.open_enrollment_period = (plan_year.open_enrollment_start_on..plan_year.open_enrollment_end_on)

    # "aasm_state"=>"active",
    # "imported_plan_year"=>false,
    # "updated_by_id"=>BSON::ObjectId('5909e07d082e766d68000078'),

    @benefit_sponsor_catalog = benefit_sponsorship.benefit_sponsor_catalog_for(benefit_application.effective_period.min)
    benefit_application.benefit_sponsor_catalog = @benefit_sponsor_catalog

    plan_year.benefit_groups.each do |benefit_group|
      params = santize_benefit_group_attrs(benefit_group)
      BenefitSponsors::Importers::BenefitPackageImporter.call(benefit_application, params)
    end

    if plan_year.is_conversion
      aasm_state = :imported
    else
    end

    benefit_application.aasm_state = benefit_application.matching_state_for(plan_year)
    @benefit_sponsor_catalog =  nil
    construct_workflow_state_transitions(benefit_application, plan_year)
    benefit_application
  end

  def santize_benefit_group_attrs(benefit_group)
    attributes = benefit_group.attributes.slice(
      :title, :description, :created_at, :updated_at, :is_active, :effective_on_kind,
      :plan_option_kind, :relationship_benefits, :dental_relationship_benefits
      )

    attributes[:is_default] = benefit_group.default
    attributes[:reference_plan_hios_id] = benefit_group.reference_plan.hios_id
    attributes[:dental_reference_plan_hios_id] = benefit_group.dental_reference_plan.hios_id if benefit_group.is_offering_dental?
    attributes
  end

  def construct_workflow_state_transitions(benefit_application, plan_year)
    plan_year.workflow_state_transitions.asc(:transition_at).each do |wst|
      benefit_application.workflow_state_transitions.build(wst.attributes.except(:_id))
    end
  end

  # Verify if there're any duplicate/fake feins
  def new_org(old_org)
    BenefitSponsors::Organizations::Organization.where(fein: old_org.fein).present?
  end
end