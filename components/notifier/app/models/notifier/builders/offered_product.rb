module Notifier
  module Builders::OfferedProduct

    def offered_products
      benefit_application = load_benefit_application
      enrollments = benefit_application.hbx_enrollments_by_month(TimeKeeper.date_of_record.next_month.beginning_of_month)
      merge_model.offered_products = build_offered_products(enrollments)
    end

    def build_offered_products(enrollments)
      enrollments.group_by(&:product_id).collect do |product_id, enrollments|
        build_offered_product(product_id, enrollments)
      end
    end

    def build_offered_product(product_id, enrollments)
      offered_product = Notifier::MergeDataModels::OfferedProduct.new
      product = BenefitMarkets::Products::Product.find(product_id)
      offered_product.product_name = product.title
      offered_product.enrollments = build_enrollments(enrollments)
      offered_product
    end

    def build_enrollments(enrollments)
      enrollments.collect do |enr|
        enrollment = Notifier::MergeDataModels::Enrollment.new
        enrollment.plan_name = enr.product.title
        enrollment.employee_responsible_amount = enr.total_employer_contribution
        enrollment.employer_responsible_amount = enr.total_employee_cost
        enrollment.premium_amount = enr.total_premium

        employee = enr.subscriber.person
        enrollment.subscriber = MergeDataModels::Person.new(first_name: employee.first_name, last_name: employee.last_name)
      
        dependents = enr.hbx_enrollment_members.reject{|member| member.is_subscriber}
        dependents.each do |dependent|
          enrollment.dependents << MergeDataModels::Person.new(first_name: dependent.person.first_name, last_name: dependent.person.last_name)
        end

        enrollment
      end
    end
  end
end