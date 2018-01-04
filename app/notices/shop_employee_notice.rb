class ShopEmployeeNotice < Notice

  Required= Notice::Required + []

  attr_accessor :census_employee

  def initialize(census_employee, args = {})
    self.census_employee = census_employee
    args[:recipient] = census_employee.employee_role.person
    args[:market_kind]= 'shop'
    args[:notice] = PdfTemplates::EmployeeNotice.new
    args[:to] = census_employee.employee_role.person.work_email_or_best
    args[:name] = census_employee.employee_role.person.full_name
    args[:recipient_document_store]= census_employee.employee_role.person
    self.header = "notices/shared/shop_header.html.erb"
    super(args)
  end

  def deliver
    build
    generate_pdf_notice
    attach_envelope
    upload_and_send_secure_message
    send_generic_notice_alert
  end

  def build
    notice.mpi_indicator = self.mpi_indicator
    notice.notification_type = self.event_name
    notice.primary_fullname = census_employee.employee_role.person.full_name.titleize
    notice.employer_name = census_employee.employer_profile.legal_name.titleize
    notice.primary_email = census_employee.employee_role.person.work_email_or_best
    append_hbe
    append_address(census_employee.employee_role.person.mailing_address)
    append_broker(census_employee.employer_profile.broker_agency_profile)
  end

  def attach_envelope
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'taglines.pdf')]
  end

  def non_discrimination_attachment
    join_pdfs [notice_path, Rails.root.join('lib/pdf_templates', 'shop_non_discrimination_attachment.pdf')]
  end

  def append_hbe
    notice.hbe = PdfTemplates::Hbe.new({
      url: "www.dhs.dc.gov",
      phone: "(855) 532-5465",
      fax: "(855) 532-5465",
      email: "#{Settings.contact_center.email_address}",
      address: PdfTemplates::NoticeAddress.new({
        street_1: "100 K ST NE",
        street_2: "Suite 100",
        city: "Washington DC",
        state: "DC",
        zip: "20005"
      })
    })
  end

  def append_address(primary_address)
    notice.primary_address = PdfTemplates::NoticeAddress.new({
      street_1: primary_address.address_1.titleize,
      street_2: primary_address.address_2.titleize,
      city: primary_address.city.titleize,
      state: primary_address.state,
      zip: primary_address.zip
      })
  end

  def append_broker(broker)
    return if broker.blank?
    location = broker.organization.primary_office_location
    broker_role = broker.primary_broker_role
    person = broker_role.person if broker_role
    return if person.blank? || location.blank?

    notice.broker = PdfTemplates::Broker.new({
      primary_fullname: person.full_name,
      organization: broker.legal_name,
      phone: location.phone.try(:to_s),
      email: (person.home_email || person.work_email).try(:address),
      web_address: broker.home_page,
      address: PdfTemplates::NoticeAddress.new({
        street_1: location.address.address_1,
        street_2: location.address.address_2,
        city: location.address.city,
        state: location.address.state,
        zip: location.address.zip
      })
    })
  end

end
