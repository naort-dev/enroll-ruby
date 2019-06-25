module Queries
  class FamilyDatatableQuery

    attr_reader :search_string, :custom_attributes

    def datatable_search(string)
      @search_string = string
      self
    end

    def initialize(attributes)
      @custom_attributes = attributes
      @skip = 0
      @limit = 25
    end

    def person_search search_string
      return Family if search_string.blank?
    end

    def build_scope()
      family = Family.where("is_active" => true)
      person = Person
      if @custom_attributes['families'] == 'by_enrollment_individual_market'
        family = family.all_enrollments
        family = family.by_enrollment_individual_market
      end
      if @custom_attributes['families'] == 'by_enrollment_shop_market'
        family = family.all_enrollments
        family = family.by_enrollment_shop_market
      end
      if @custom_attributes['families'] == 'non_enrolled'
        family = family.non_enrolled
      end
      if @custom_attributes['families'] == 'by_enrollment_coverall'
        resident_ids = Person.all_resident_roles.pluck(:_id)
        family = family.where('family_members.person_id' => {"$in" => resident_ids})
      end
      if @custom_attributes['employer_options'] == 'by_enrollment_renewing'
        family = family.by_enrollment_renewing
      end
      if @custom_attributes['employer_options'] == 'sep_eligible'
        family = family.sep_eligible
      end
      if @custom_attributes['employer_options'] == 'coverage_waived'
        family = family.coverage_waived
      end
      if @custom_attributes['individual_options'] == 'all_assistance_receiving'
        family = family.all_assistance_receiving
      end
      if @custom_attributes['individual_options'] == 'sep_eligible'
        family = family.sep_eligible
      end
      if @custom_attributes['individual_options'] == 'all_unassisted'
        family = family.all_unassisted
      end
      #add other scopes here
      return family if @search_string.blank? || @search_string.length < 2
      person_id = Person.search(@search_string, nil, nil).pluck(:_id)
      #Caution Mongo optimization on chained "$in" statements with same field
      #is to do a union, not an interactionl
      family_scope = family.and('family_members.person_id' => {"$in" => person_id})
      return family_scope if @order_by.blank?
      family_scope.order_by(@order_by)
    end

    def each
      return to_enum(:each) unless block_given?
      limited_scope, active_enrollment_cache = build_iteration_caches
      limited_scope.each do |fam|
        fam.set_active_admin_dt_enrollments(active_enrollment_cache[fam.active_household.id])
        yield fam
      end
    end

    def each_with_index
      return to_enum(:each_with_index) unless block_given?
      limited_scope, active_enrollment_cache = build_iteration_caches
      limited_scope.each_with_index do |fam, idx|
        fam.set_active_admin_dt_enrollments(active_enrollment_cache[fam.active_household.id])
        yield fam, idx if block_given?
      end
    end

    def skip(num)
      @skip = num
      self
    end

    def limit(num)
      @limit = num
      self
    end

    def order_by(var)
      @order_by = var
      self
    end

    def klass
      Family
    end

    def size
      build_scope.count
    end

    private

    def build_iteration_caches
      skipped_scope = apply_skip(build_scope)
      limited_scope = apply_limit(skipped_scope)
      family_ids = limited_scope.pluck(:id)
      active_enrollment_cache = load_active_enrollment_cache_for(family_ids)
      [limited_scope, active_enrollment_cache]
    end

    def load_active_enrollment_cache_for(family_ids)
      enrollment_cache = Hash.new { |h, k| h[k] = Array.new }
      HbxEnrollment.active.enrolled_and_renewing.where(:family_id => {"$in" => family_ids}).each do |en|
        enrollment_cache[en.household_id] = enrollment_cache[en.household_id] + [en]
      end
      enrollment_cache
    end

    def apply_skip(scope)
      return scope unless @skip
      scope.skip(@skip)
    end

    def apply_limit(scope)
      return scope unless @limit
      scope.limit(@limit)
    end

  end
end
