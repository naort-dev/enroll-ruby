require File.join(Rails.root, "lib/mongoid_migration_task")

class AddingDependents < MongoidMigrationTask
  def migrate
    file_name = ENV['file_name'].to_s
    family_id = ENV['family_id'].to_s
    index = 1
    family = Family.find(family_id)
    CSV.foreach("#{Rails.root}/#{file_name}", headers: true) do |row|
      person = Person.where(hbx_id: row['hbx_id']).first_or_create
      person.first_name =  row['FirstName']
      person.middle_name = row['MiddleName']
      person.last_name = row['LastName']
      person.dob = Date.parse(row['DOB']) 
      person.ssn = row['SSN']
      person.gender = row['Gender']
      #, relationship: row['Relationship']
      if person.save
        puts "Person record created for row #{index}." unless Rails.env.test?
        family_member = FamilyMember.new(person_id: person.id)
        if family.family_members <<  family_member
          puts "Dependent added for family with family member id: #{family_member.id}"
        end
      else
        puts person.errors.full_messages
        puts "Person record doesn't created for row #{index}" unless Rails.env.test?
      end
      index += 1
    end
  end
end