module Statuses
  class StatusFlowComponent < ViewComponent::Base
    def initialize(resource)
      @resource = resource
    end

    def render?
      @resource.present?
    end

    private

    # główny flow - różny dla każdego modelu
    def main_flow
      case @resource.class.name
      when "Offer"
        [:brand_new, :in_preparation, :sent, :accepted, :converted_to_order]
      when "Order"
        [:brand_new, :in_preparation, :approved, :in_progress, :ready, :completed, :closed]
      else
        []
      end
    end

    # statusy poza flow
    def alternative_statuses
      case @resource.class.name
      when "Offer"
        [:not_accepted, :rejected]
      when "Order"
        [:cancelled, :on_hold, :complaint]
      else
        []
      end
    end

    def status_label_i18n(status)
      I18n.t("activerecord.attributes.#{@resource.class.name.underscore}.statuses.#{status}")
    end

    def current?(status)
      @resource.aasm.current_state == status.to_sym
    end

    # możliwość przejścia do danego statusu
    def may_send?(status)
      event = @resource.class.event_for_status(status)
      return false unless event
      
      @resource.send("may_#{event}?")
    end

    # główny flow statusów
    def main_flow_items
      main_flow.each_with_index.map do |status, index|
        {
          status: status,
          event: @resource.class.event_for_status(status),
          available: may_send?(status),
          color: status_color(status),
          has_arrow: index < main_flow.length - 1,
          actions: current?(status) ? @resource.status_actions : []
        }
      end
    end

    # statusy poza flow (odrzucenie)
    def alternative_items
      alternative_statuses.map do |status|
        {
          status: status,
          event: @resource.class.event_for_status(status),
          available: may_send?(status),
          color: status_color(status),
          actions: current?(status) ? @resource.status_actions : []
        }
      end
    end

    def status_color(status)
      @resource.class.status_color(status.to_s)
    end

    def change_status_path(event)
      case @resource.class.name
      when "Offer"
        helpers.change_status_offer_path(@resource, event: event)
      when "Order"
        helpers.change_status_order_path(@resource, event: event)
      end
    end
  end
end

