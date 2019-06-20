all_families = Family.outstanding_verification.where(:'households.hbx_enrollments.is_any_enrollment_member_outstanding' => true)

all_families.each do |family|
  begin
    family.update_attributes!(min_verification_due_date: family.min_verification_due_date_on_family)
  rescue Exception => e
    puts "Resolve errors with family of id: #{family.id}"
    puts "#{e}"
  end
end

