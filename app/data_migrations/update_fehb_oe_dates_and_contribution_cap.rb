# frozen_string_literal: true

require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateFehbOeDatesAndContributionCap < MongoidMigrationTask

  def migrate
    action = ENV['action'].to_s
    feins = ENV['feins'].split(' ').uniq
    feins.each do |fein|
      organization = BenefitSponsors::Organizations::Organization.where(fein: fein).first
      benefit_application = organization.employer_profile.benefit_applications.draft.first

      case action
      when 'update_open_enrollment_dates'
        update_open_enrollment_dates(benefit_application)
      when 'update_contribution_cap'
        update_contribution_cap(benefit_application)
      when 'begin_open_enrollment'
        begin_open_enrollment(benefit_application)
      else

      end
    end
  end

  def update_open_enrollment_dates(benefit_application)
    oe_start_on = DateTime.strptime(ENV['oe_start_on'].to_s, "%m/%d/%Y")
    oe_end_on = DateTime.strptime(ENV['oe_end_on'].to_s, "%m/%d/%Y")

    benefit_application.update_attributes("open_enrollment_period" => oe_start_on..oe_end_on)
  rescue StandardError => e
    puts e.message
  end

  def update_contribution_cap(benefit_application)
    contribution_levels = benefit_application.benefit_packages.first.sponsored_benefits.first.sponsor_contribution.contribution_levels
    contribution_levels.where(:display_name => 'Employee Only').first.update_attributes(contribution_cap: ENV['employee_only_cap']) if ENV['employee_only_cap']
    contribution_levels.where(:display_name => 'Employee + 1').first.update_attributes(contribution_cap: ENV['employee_plus_one_cap']) if ENV['employee_plus_one_cap']
    contribution_levels.where(:display_name => 'Family').first.update_attributes(contribution_cap: ENV['family_cap']) if ENV['family_cap']
  rescue StandardError => e
    puts e.message
  end

  def begin_open_enrollment(benefit_application)
    benefit_application.approve_application! if benefit_application.may_approve_application?
    oe_period = benefit_application.open_enrollment_period

    if TimeKeeper.date_of_record >= oe_period.begin
      benefit_application.begin_open_enrollment! if benefit_application.may_begin_open_enrollment?
      benefit_application.update(open_enrollment_period: (today..oe_period.end))
    end
  rescue StandardError => e
    puts e.message
  end
end