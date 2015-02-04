class Employer
  include Mongoid::Document
  include Mongoid::Timestamps

  include AASM

  ENTITY_KINDS = [:c_corporation, :s_corporation, :partnership, :tax_exempt_organization]

  auto_increment :hbx_id, type: Integer

  # Employer registered legal name
  field :name, type: String

  # Doing Business As (alternate employer name)
  field :dba, type: String

  # Federal Employer ID Number
  field :fein, type: String
  field :entity_kind, type: String
  field :sic_code, type: String

  field :aasm_state, type: String
  field :aasm_message, type: String

  field :is_active, type: Boolean, default: true

  embeds_many :contacts
  embeds_many :employer_census_families, class_name: "EmployerCensus::Family"
  embeds_many :plan_years

  belongs_to :broker_agency, counter_cache: true
  has_many :representatives, class_name: "Person", inverse_of: :employer_representatives

  # has_many :premium_payments, order: { paid_at: 1 }
  index({ hbx_id: 1 }, { unique: true })
  index({ name: 1 })
  index({ dba: 1 }, {sparse: true})
  index({ fein: 1 }, { unique: true })
  index({ broker_agency_id: 1}, {sparse: true})
  index({ aasm_state: 1 })
  index({ is_active: 1 })

  # PlanYear child model indexes
  index({"plan_year.start_date" => 1})
  index({"plan_year.end_date" => 1}, {sparse: true})
  index({"plan_year.open_enrollment_start" => 1})
  index({"plan_year.open_enrollment_end" => 1})

  index({"employer_census_families._id" => 1})
  index({"employer_census_families.employer_census_employee.last_name" => 1})
  index({"employer_census_families.employer_census_employee.dob" => 1})
  index({"employer_census_families.employer_census_employee.ssn" => 1})
  index({"employer_census_families.employer_census_employee.ssn" => 1,
         "employer_census_families.employer_census_employee.dob" => 1},
         {name: "ssn_dob_index"})

  validates_presence_of :name, :fein, :entity_kind

  validates :fein,
    length: { is: 9, message: "%{value} is not a valid FEIN" },
    numericality: true,
    uniqueness: true

  validates :entity_kind,
    inclusion: { in: ENTITY_KINDS, message: "%{value} is not a valid business entity" },
    allow_blank: false

  ## Class methods
  def self.find_by_broker(broker)
    return if broker.blank?
    where(broker_agency_id: broker._id)
  end

  # has_many employees
  def employees
    Employee.where(employer_id: self._id)
  end

  def payment_transactions
    PremiumPayment.payment_transactions_for(self)
  end

  # def associate_all_carriers_and_plans_and_brokers
  #   self.policies.each { |pol| self.carriers << pol.carrier; self.brokers << pol.broker; self.plans << pol.plan }
  #   save!
  # end

  #TODO: Seperate enrollment_open/closed into different state
  aasm do
    state :applicant, initial: true
    state :approval_pending
    state :approved
    state :approval_denied
    state :enrollment_open
    state :enrollment_closed
    state :pending_binder_payment
    state :terminated

    event :update_application do
      transitions from: [:approval_pending,
          :approved,
          :approval_denied,
          :enrollment_open,
          :enrollment_closed,
          :pending_binder_payment,
          :terminated
        ], to: :approval_pending
    end

    event :submit_employer do
      transitions from: :applicant, to: :approval_pending
    end

    event :approve_employer do
      transitions from: :approval_pending, to: :approved
    end

    event :deny_employer do
      transitions from: :approval_pending, to: :approval_denied
    end

    event :start_enrollment do
      transitions from: [:approved, :enrollment_closed], to: :enrollment_open
    end

    event :end_enrollment do
      transitions from: :enrollment_open, to: :enrollment_closed
    end

    event :receive_binder_payment do
      transitions from: :pending_binder_payment, to: :binder_payment_received
    end

    event :terminate_employer do
      transitions from: [:binder_payment_received, :enrollment_open, :enrollment_closed], to: :terminated
    end
  end

  # Strip non-numeric characters
  def fein=(new_fein)
    return if new_fein.blank?
    write_attribute(:fein, new_fein.to_s.gsub(/[^0-9]/i, ''))
  end

  def todays_bill
    e_id = self._id
    value = Policy.collection.aggregate(
      { "$match" => {
        "employer_id" => e_id,
        "enrollment_members" =>
        {
          "$elemMatch" => {"$or" => [{
            "coverage_end" => nil
          },
          {"coverage_end" => { "$gt" => Time.now }}
          ]}

        }
      }},
      {"$group" => {
        "_id" => "$employer_id",
        "total" => { "$addToSet" => "$pre_amt_tot" }
      }}
    ).first["total"].inject(0.00) { |acc, item|
      acc + BigDecimal.new(item)
    }
    "%.2f" % value
  end

  def self.find_for_fein(e_fein)
    Employer.where(:fein => e_fein).first
  end

  def plan_year_of(coverage_start_date)
    # The #to_a is a caching thing.
    plan_years.to_a.detect do |py|
      (py.start_date <= coverage_start_date) &&
        (py.end_date >= coverage_start_date)
    end
  end

  def renewal_plan_year_of(coverage_start_date)
    plan_year_of(coverage_start_date + 1.year)
  end

  class << self
    def find_or_create_employer(m_employer)
      found_employer = Employer.where(
        :hbx_id => m_employer.hbx_id
      ).first
      return found_employer unless found_employer.nil?
      m_employer.save!
      m_employer
    end

    def find_or_create_employer_by_fein(m_employer)
      found_employer = Employer.find_for_fein(m_employer.fein)
      return found_employer unless found_employer.nil?
      m_employer.save!
      m_employer
    end
  end

  def is_active?
    self.is_active
  end


end
