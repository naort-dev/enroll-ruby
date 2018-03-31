module Services
  class NoticeService
    include Acapi::Notifiers

    attr_accessor :legacy_triggers

    def deliver(recipient:, event_object:, notice_event:)
      delivery_method = can_be_proccessed_as_legacy?(recipient, notice_event) ? :create_notice_job : :trigger_notice_event
      send(delivery_method, recipient, event_object, notice_event)
    end

    def create_notice_job(recipient, event_object, notice_event)
      ShopNoticesNotifierJob.perform_later(recipient.id.to_s, notice_event)
    end

    def trigger_notice_event(recipient, event_object, notice_event)
      resource = Notifier::ApplicationEventMapper.map_resource(recipient.class)
      event_name = Notifier::ApplicationEventMapper.map_event_name(resource, notice_event)
      notify(event_name, {
        resource.identifier_key => recipient.send(resource.identifier_method).to_s,
        :event_object_kind => event_object.class.to_s,
        :event_object_id   => event_object.id.to_s
        })
    end

    def can_be_proccessed_as_legacy?(recipient, notice_event)
      resource = Notifier::ApplicationEventMapper.map_resource(recipient.class)
      ApplicationEventKind.where(event_name: notice_event, resource_name: resource.resource_name.to_s).present?
    end
  end
end