class IvlNotices::EnrollmentNoticeBuilder < IvlNotice

  def initialize(consumer_role, args = {})
    args[:recipient] = consumer_role.person.families.first.primary_applicant.person
    args[:notice] = PdfTemplates::ConditionalEligibilityNotice.new
    args[:market_kind] = 'individual'
    args[:recipient_document_store]= consumer_role.person.families.first.primary_applicant.person
    args[:to] = consumer_role.person.families.first.primary_applicant.person.work_email_or_best
    self.header = "notices/shared/header_ivl.html.erb"
    super(args)
  end

  def attach_required_documents
    # attach_blank_page
    generate_custom_notice('notices/ivl/documents_section')
    join_pdfs [notice_path, Rails.root.join("tmp", "documents_section_#{notice_filename}.pdf")]
  end

  def generate_custom_notice(custom_template)
    File.open(custom_notice_path, 'wb') do |file|
      file << self.pdf(custom_template)
    end
    # clear_tmp
  end

  def custom_notice_path
    Rails.root.join("tmp", "documents_section_#{notice_filename}.pdf")
  end

  def deliver
    build
    # generate_pdf_notice
    attach_required_documents
    # attach_blank_page
    # attach_voter_application
    # prepend_envelope
    upload_and_send_secure_message

    if recipient.consumer_role.can_receive_electronic_communication?
      send_generic_notice_alert
    end

    if recipient.consumer_role.can_receive_paper_communication?
      store_paper_notice
    end
  end

  def attach_voter_application
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'voter_application.pdf')]
  end

  def build
    notice.mpi_indicator = self.mpi_indicator
    check_for_unverified_individuals
    append_data
    notice.primary_fullname = recipient.full_name.titleize || ""
    if recipient.mailing_address
      append_address(recipient.mailing_address)
    else
      # @notice.primary_address = nil
      raise 'mailing address not present'
    end
  end


  def check_for_unverified_individuals
    enrollments = recipient.primary_family.households.flat_map(&:hbx_enrollments).select do |hbx_en|
      (!hbx_en.is_shop?) && (!["coverage_canceled", "shopping", "inactive"].include?(hbx_en.aasm_state)) &&
        (
          hbx_en.terminated_on.blank? ||
          hbx_en.terminated_on >= TimeKeeper.date_of_record
        )
    end
    enrollments.reject!{|e| e.coverage_terminated? }
    family_members = enrollments.inject([]) do |family_members, enrollment|
      family_members += enrollment.hbx_enrollment_members.map(&:family_member)
    end.uniq

    people = family_members.map(&:person).uniq
    # people.reject!{|p| p.consumer_role.aasm_state != 'verification_outstanding'}
    # people.reject!{|person| !ssn_outstanding?(person) && !lawful_presence_outstanding?(person) }

    outstanding_people = []
    people.each do |person|
      if person.consumer_role.outstanding_verification_types.present?
        outstanding_people << person
      end
    end
    outstanding_people.uniq!
    notice.documents_needed = outstanding_people.present? ? true : false
    append_unverified_individuals(outstanding_people)
  end

  def lawful_presence_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?('Citizenship') || person.consumer_role.outstanding_verification_types.include?('Immigration status')
  end

  def ssn_outstanding?(person)
    person.consumer_role.outstanding_verification_types.include?("Social Security Number")
  end

  def append_unverified_individuals(people)
    people.each do |person|
      if ssn_outstanding?(person)
        notice.ssa_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: TimeKeeper.date_of_record+95.days, age: person.age_on(TimeKeeper.date_of_record) })
      end

      if lawful_presence_outstanding?(person)
        notice.dhs_unverified << PdfTemplates::Individual.new({ full_name: person.full_name.titleize, documents_due_date: TimeKeeper.date_of_record+95.days, age: person.age_on(TimeKeeper.date_of_record) })
      end
    end
  end

  def append_data
    family = recipient.primary_family
    #temporary fix - in case of mutliple applications
    latest_application = family.applications.where(:aasm_state.nin => ["draft"]).sort_by(&:submitted_at).last
    notice.assistance_year = latest_application.assistance_year

    family.enrollments.enrolled_and_renewing.each do |enrollment|
      notice.enrollments << append_enrollment_information(enrollment)
    end
    hbx = HbxProfile.current_hbx
    bc_period = hbx.benefit_sponsorship.benefit_coverage_periods.detect { |bcp| bcp if (bcp.start_on..bcp.end_on).cover?(TimeKeeper.date_of_record.next_year) }
    notice.ivl_open_enrollment_start_on = bc_period.open_enrollment_start_on
    notice.ivl_open_enrollment_end_on = bc_period.open_enrollment_end_on
  end

  def append_enrollment_information(enrollment)
    plan = PdfTemplates::Plan.new({
      plan_name: enrollment.plan.name,
      is_csr: enrollment.plan.is_csr?,
      coverage_kind: enrollment.plan.coverage_kind,
      plan_carrier: enrollment.plan.carrier_profile.organization.legal_name
      })
    PdfTemplates::Enrollment.new({
      premium: enrollment.total_premium.round(2),
      aptc_amount: enrollment.applied_aptc_amount.round(2),
      responsible_amount: (enrollment.total_premium - enrollment.applied_aptc_amount.to_f).round(2),
      phone: enrollment.phone_number,
      is_receiving_assistance: (enrollment.applied_aptc_amount > 0 || enrollment.plan.is_csr?) ? true : false,
      coverage_kind: enrollment.coverage_kind,
      effective_on: enrollment.effective_on,
      plan: plan,
      enrollees: enrollment.hbx_enrollment_members.inject([]) do |enrollees, member|
        enrollee = PdfTemplates::Individual.new({
          full_name: member.person.full_name,
          age: member.person.age_on(TimeKeeper.date_of_record)
        })
        enrollees << enrollee
      end
    })
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: capitalize_quadrant(primary_address.address_1.to_s.titleize),
      street_2: capitalize_quadrant(primary_address.address_2.to_s.titleize),
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def capitalize_quadrant(address_line)
    address_line.split(/\s/).map do |x|
      x.strip.match(/^NW$|^NE$|^SE$|^SW$/i).present? ? x.strip.upcase : x.strip
    end.join(' ')
  end

end