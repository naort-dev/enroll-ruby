module Forms
  class BulkActionsForAdmin
    include Acapi::Notifiers

    attr_reader :result
    attr_reader :row
    attr_reader :family_id
    attr_reader :params
    attr_reader :config

    def initialize(*arguments)
      @params = arguments.extract_options!
      @result = {success: [], failure: []}
      @row = @params[:family_actions_id]
      @family_id = @params[:family_id]
      @config = Rails.application.config.acapi
    end

    def cancel_enrollments
      cancelled_enrollments_transmission_info = {}
      @params.each do |key, value|
        if key.to_s[/cancel_hbx_.*/]
          hbx = HbxEnrollment.find(params[key.to_s])
          begin
            hbx.cancel_coverage! if hbx.may_cancel_coverage?
            @result[:success] << hbx
            cancelled_enrollments_transmission_info[hbx.id] = params.key?("transmit_hbx_#{hbx.id.to_s}") ? true : false
          rescue
            @result[:failure] << hbx
          end
        end
      end
      cancelled_enrollments_transmission_info.each { |hbx_id, transmit_flag| handle_edi_transmissions(hbx_id, transmit_flag) }
    end

    def terminate_enrollments
      terminated_enrollments_transmission_info = {}
      @params.each do |key, value|
        if key.to_s[/terminate_hbx_.*/]
          hbx = HbxEnrollment.find(params[key.to_s])
          begin
            termination_date = Date.strptime(params["termination_date_#{value}"], "%m/%d/%Y")
            hbx.terminate_coverage!(termination_date) if hbx.may_terminate_coverage?
            @result[:success] << hbx
            terminated_enrollments_transmission_info[hbx.id] = params.key?("transmit_hbx_#{hbx.id.to_s}") ? true : false
          rescue
            @result[:failure] << hbx
          end
        end
      end
      terminated_enrollments_transmission_info.each { |hbx_id, transmit_flag| handle_edi_transmissions(hbx_id, transmit_flag) }
    end

    def transition_family_members
      # Handle transitions here
      params.each do |key, value|
        if key.to_s[/transition_user_.*/]
          person = Person.find(value)
          market_kind = params["transition_market_kind_#{value}"]
          effective_date = Date.strptime(params["transition_effective_date_#{value}"], "%m/%d/%Y")
          transition_reason = params["transition_reason_#{value}"]
          person.individual_market_transitions.build(role_type: market_kind, effective_starting_on: effective_date, reason_code: transition_reason, submitted_at: ::TimeKeeper.datetime_of_record)

          begin
            person.save!
            @result[:success] << person
            # handle endating previous transition(s)
            # creation of SEP?
          rescue
            @result[:failure] << person
          end
        end
      end
    end

    private

    def handle_edi_transmissions(hbx_id, transmit_flag) #transmit_flag = true/false based on wheather the user elected to transmit.
      hbx = HbxEnrollment.find(hbx_id)
      ### Handle EDI transmission here ###
      notify(
        "acapi.info.events.hbx_enrollment.terminated",
        {
          :reply_to => "#{config.hbx_id}.#{config.environment_name}.q.glue.enrollment_event_batch_handler",
          "hbx_enrollment_id" => hbx.hbx_id,
          "enrollment_action_uri" => "urn:openhbx:terms:v1:enrollment#terminate_enrollment",
          "is_trading_partner_publishable" => transmit_flag
        }
      )
    end
  end
end
