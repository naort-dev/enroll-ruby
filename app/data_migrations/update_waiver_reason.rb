require File.join(Rails.root, "lib/mongoid_migration_task")

class UpdateWaiverReason < MongoidMigrationTask
  def migrate
    begin
      id = ENV['id'].to_s
      waiver_reason = ENV['waiver_reason'].to_s
      hbx_id = HbxEnrollment.by_hbx_id(id)
      if hbx_id.nil?
        puts "No enrollment was found for the given hbx_id"
      else
        puts "#{hbx_id}"
        hbx_id.first.update_attributes!(waiver_reason:waiver_reason)
        puts "Updated waiver reason to #{waiver_reason}"
      end
    rescue
      puts "Couldn't update the waiver reason for the enrollment #{hbx_id}"
    end
  end
end