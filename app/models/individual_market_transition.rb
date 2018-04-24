class IndividualMarketTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include SetCurrentUser

  embedded_in :person

  ROLE_TYPES   = %W(consumer resident)
  REASON_CODES = %W(reason1 reason2 generating_consumer_role generating_resident_role)

  field :role_type, type: String
  field :effective_starting_on, type: Date
  # make ending on default to nil to help enforce logic that it needs to be set upon a market transtion so there is always
  # a single individual_market_transition on a person that is not nil, e.g. the active role
  field :effective_ending_on, type: Date, default: nil
  field :reason_code, type: String
  field :submitted_at, type: DateTime, default: nil
  field :user_id, type: BSON::ObjectId


	validates_presence_of :submitted_at

  validates :role_type,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: ROLE_TYPES, message: "%{value} is not a valid individual market role type"}

  validates :reason_code,
          presence: true,
          allow_blank: false,
          allow_nil:   false,
          inclusion: {in: REASON_CODES, message: "%{value} is not a valid transistion reason code"}

  before_validation :set_submitted_at, :set_submitted_by

  def set_submitted_at
    self.submitted_at ||= TimeKeeper.datetime_of_record
  end

  #TODO set the id of the admin who is making the transition before saving
  def set_submitted_by

  end

  def self.all
    Person.all_individual_market_transitions
  end
end
