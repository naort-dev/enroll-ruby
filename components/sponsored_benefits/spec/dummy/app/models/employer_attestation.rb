class EmployerAttestation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :aasm_state, type: String, default: "unsubmitted"
end
