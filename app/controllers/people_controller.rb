class PeopleController < ApplicationController

  def new
    @person = Person.new
    build_nested_models
    # render action: "new", layout: "form"
  end

  # Uses identifying information to return single pre-existing Person instance if already in DB
  def match_person
    
    @person = Person.new(person_params)

    matched_person = Person.match_by_id_info(@person)
    if matched_person.blank?
      # Preexisting Person not found, create new instance and return to complete form entry
      respond_to do |format|
        format.json { render json: { person: @person, matched: false}, status: :ok, location: @person }
      end
    else
      # Matched Person, autofill form with found attributes
      respond_to do |format|
        @person = matched_person.first
        build_nested_models
        format.json { render json: { person: @person, matched: true}, status: :ok, location: @person, matched: true }
      end
    end
  end

  # Uses identifying information to return one or more for matches in employer census
  def match_employer
  end

  def link_employer
  end
  
  def get_employer
    @employers = Employer.all

    respond_to do |format|
      format.js {}
    end
  end
  
  def person_confirm
    @employe_family = EmployerCensus::EmployeeFamily.last

    respond_to do |format|
      format.js {}
    end
  end
  

  def update
    @person = Person.find(params[:id])
    @person.updated_by = current_user.email unless current_user.nil?

    respond_to do |format|
      if @person.update_attributes(params[:person])
        format.html { redirect_to @person, notice: 'Person was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    
    person_params["addresses_attributes"].each do |key, address|
      if address["kind"] != 'home' && (address["city"].blank? && address["zip"].blank? && address["address_1"].blank?) 
        person_params["addresses_attributes"].delete("#{key}")
      end
    end
    puts person_params
    @person = Person.new(person_params)
    respond_to do |format|
      if @person.save(validate: false)
        format.html { redirect_to @person, notice: 'Person was successfully created.' }
        format.json { render json: @person, status: :created, location: @person }
      else
        build_nested_models
        format.html { render action: "new" }
        format.json { render json: @person.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @person = Person.find(params[:id])
    build_nested_models
  end
  
   def show
    @person = Person.find(params[:id])
    build_nested_models
  end
  

private
  def build_nested_models
    
    ["home","mobile","work","fax"].each do |kind|
       @person.phones.build(kind: kind) if @person.phones.select{|phone| phone.kind == kind}.blank?
    end
   
    Address::KINDS.each do |kind|
      @person.addresses.build(kind: kind) if @person.addresses.select{|address| address.kind == kind}.blank?
    end
    
    ["home","work"].each do |kind|
       @person.emails.build(kind: kind) if @person.emails.select{|email| email.kind == kind}.blank?
    end
  end
  
  def person_params
    params.require(:person).permit!
  end

end
