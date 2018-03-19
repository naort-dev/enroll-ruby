module SponsoredBenefits
  module BenefitMarkets
    class AcaIndividualConfiguration < Configuration

      embedded_in :configurable, polymorphic: true

      field :mm_enr_due_on,        as: :monthly_enrollment_due_on, type: Integer, default: 15
      field :vr_os_window,         as: :verification_outstanding_window_days, type: Integer, default: 0
      field :vr_due,               as: :verification_due_days, type: Integer, default: 95
      field :open_enrl_start_on,   as: :open_enrollment_start_on, type: Date, default: Date.new(2017,11,1)
      field :open_enrl_end_on,     as: :open_enrollment_end_on, type: Date, default: Date.new(2017,01,31)

      embeds_one :initial_configuration,  class_name: "SponsoredBenefits::BenefitMarkets::AcaInitialIndividualConfiguration",
                                          autobuild: true
    end
  end
end
