FactoryGirl.define do
  factory(:generative_individual, {class: Person}) do
    first_name { Forgery(:name).first_name }
    last_name { Forgery(:name).first_name }
    gender { Forgery(:personal).gender }
    dob { Date.today }
    addresses {
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_address
        end
      end
    }
    phones {
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_phone
        end
      end
    }
    emails {
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_email
        end
      end
    }
    broker_role {
      FactoryGirl.build_stubbed :generative_person_broker_role, :person_obj => self
    }
    employee_roles {
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_person_employee_role, :person_obj => self
        end
      end
    }
    person_relationships {
      address_count = Random.rand(4)
      if address_count == 0
        []
      else
        (1..address_count).to_a.map do |idx|
          FactoryGirl.build_stubbed :generative_person_relationship
        end
      end
    }
    consumer_role
  end

  factory(:generative_person_relationship, {class: PersonRelationship}) do
    kind {
      pick_list = PersonRelationship::Kinds - ["head of household", "self", "unrelated", "domestic_partner", "other_tax_dependent"]
      max = pick_list.length
      pick_list[Random.rand(max)]
    }
    relative {
      FactoryGirl.build_stubbed :generative_person
    }
  end

  factory(:generative_person_employee_role, {class: EmployeeRole}) do
    transient do
      person_obj nil
    end
    person { person_obj }
  end

  factory(:generative_person_broker_role, {class: BrokerRole}) do
    transient do
      person_obj nil
    end
    person { person_obj }
    npn "123432423"
    broker_agency_profile {
      FactoryGirl.build_stubbed :generative_broker_agency_profile
    }
  end

end
