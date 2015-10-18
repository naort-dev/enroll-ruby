module ConsumerProfilesHelper
  def ethnicity_collection
    [
      ["White", "Black or African American", "Asian Indian", "Chinese" ],
      ["Filipino", "Japanese", "Korean", "Vietnamese", "Other Asian"],
      ["Native Hawaiian", "Samoan", "Guamanian or Chamorro", ],
      ["Other Pacific Islander", "American Indian or Alaskan Native", "Other"]

    ].inject([]){ |sets, ethnicities|
      sets << ethnicities.map{|e| OpenStruct.new({name: e, value: e})}
    }
  end

  def latino_collection
    [
      ["Mexican", "Mexican American"],
      ["Chicano/a", "Puerto Rican"],
      ["Cuban", "Other"]
    ].inject([]){ |sets, ethnicities|
      sets << ethnicities.map{|e| OpenStruct.new({name: e, value: e})}
    }
  end

  def find_consumer_role_for_fields(obj)
    if obj.is_a? Person
      obj.consumer_role
    elsif obj.persisted?
      obj.family_member.person.consumer_role
    else
      ConsumerRole.new
    end
  end

  def show_naturalized_citizen_container(obj)
    !obj.us_citizen.nil? and obj.us_citizen
  end

  def show_immigration_status_container(obj)
    !obj.us_citizen.nil? and !obj.us_citizen
  end

  def show_tribal_container(obj)
    !obj.indian_tribe_member.nil? and obj.indian_tribe_member
  end

  def show_naturalization_doc_type(obj)
    !obj.us_citizen.nil? and obj.us_citizen and !obj.naturalized_citizen.nil? and obj.naturalized_citizen
  end

  def show_immigration_doc_type(obj)
    !obj.us_citizen.nil? and !obj.us_citizen and !obj.eligible_immigration_status.nil? and obj.eligible_immigration_status
  end

  def show_vlp_documents_container(obj)
    show_naturalization_doc_type(obj) || show_immigration_doc_type(obj)
  end
end
