module Subscribers
  class PolicyTerminationsSubscriber < ::Acapi::Subscription
    include Acapi::Notifiers

    def self.subscription_details
      [/acapi\.info\.events\.policy\./]
    end

    def call(event_name, e_start, e_end, msg_id, payload)
      begin
        if ["canceled", "terminated"].include?(event_name.split(".").last)
          Rails.logger.error("PolicyTerminationsSubscriber") { "Began Processing" }
          Rails.logger.error("PolicyTerminationsSubscriber") { payload.inspect }
          stringed_payload = payload.stringify_keys
          qr_uri = stringed_payload["qualifying_reason"].present? ? stringed_payload["qualifying_reason"].split('#').last : nil
          policy_instance_uri = stringed_payload["resource_instance_uri"]
          end_effective_date_str = stringed_payload["event_effective_date"]
          hbx_enrollment_id_json_list = stringed_payload["hbx_enrollment_ids"]
          is_cancel = (event_name == "acapi.info.events.policy.canceled") ? true : false
          hbx_enrollment_id_uris = JSON.parse(hbx_enrollment_id_json_list)
          hbx_enrollment_ids = hbx_enrollment_id_uris.map do |heiu|
            heiu.split("#").last
          end
          enrollments = hbx_enrollment_ids.map do |hei|
            Rails.logger.error("PolicyTerminationsSubscriber") { "Searching for enrollment with ID #{hei}" }
            HbxEnrollment.by_hbx_id(hei).first
          end.compact
          Rails.logger.error("PolicyTerminationsSubscriber") { "Found #{enrollments.count} enrollments" }
          enrollments.each do |en|
            # persist reason when feature enabled
            en.update_attributes(terminate_reason: qr_uri.to_s) if EnrollRegistry.feature_enabled?(:display_ivl_termination_reason)
            if is_cancel
              Rails.logger.error("PolicyTerminationsSubscriber") { "Found and attempting to process #{en.hbx_id} as cancel" }
              next if en.coverage_canceled?
              if en.may_cancel_for_non_payment? && qr_uri=='non_payment'
                en.cancel_for_non_payment!
              elsif en.may_cancel_coverage?
                en.cancel_coverage!
              else
                # cancel termed coverage
                prevs_state = en.aasm_state
                en.update_attributes(aasm_state: "coverage_canceled", terminated_on: nil, termination_submitted_on: nil)
                en.workflow_state_transitions << WorkflowStateTransition.new(
                  from_state: prevs_state,
                  to_state: "coverage_canceled",
                  reason: "carrier initiated term"
                )
              end
            else
              Rails.logger.error("PolicyTerminationsSubscriber") { "Found and attempting to process #{en.hbx_id} as termination" }
              if en.may_terminate_for_non_payment? && qr_uri=='non_payment'
                end_effective_date = Date.strptime(end_effective_date_str, "%Y%m%d") rescue nil
                if end_effective_date
                  if en.effective_on > end_effective_date
                    en.cancel_coverage! if en.may_cancel_coverage?
                  else
                    next if en.terminated_on.present? && end_effective_date >= en.terminated_on
                    en.update_attributes(terminated_on: end_effective_date) if en.terminated_on.present?
                    en.terminate_for_non_payment!(end_effective_date)
                  end
                end
              elsif en.may_terminate_coverage?
                end_effective_date = Date.strptime(end_effective_date_str, "%Y%m%d") rescue nil
                if end_effective_date

                  if en.effective_on > end_effective_date
                    if en.may_cancel_coverage?
                      en.cancel_coverage!
                    else
                      # cancel terminated coverage
                      prevs_state = en.aasm_state
                      en.update_attributes(aasm_state: "coverage_canceled", terminated_on: nil, termination_submitted_on: nil)
                      en.workflow_state_transitions << WorkflowStateTransition.new(
                        from_state: prevs_state,
                        to_state: "coverage_canceled"
                      )
                    end
                  else
                    next if en.terminated_on.present? && end_effective_date >= en.terminated_on
                    en.update_attributes(terminated_on: end_effective_date) if en.terminated_on.present?
                    en.terminate_coverage!(end_effective_date)
                  end
                end
              end
            end
          end
        else
          Rails.logger.error("PolicyTerminationsSubscriber") { "Ignoring event #{event_name}" }
        end
      rescue Exception => e
        Rails.logger.error("PolicyTerminationsSubscriber") { e.to_s } unless Rails.env.test?
      end
    end
  end
end
