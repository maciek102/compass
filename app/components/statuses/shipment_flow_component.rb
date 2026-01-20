module Statuses
  class ShipmentFlowComponent < ViewComponent::Base
    def initialize(shipment)
      @shipment = shipment
    end

    def render?
      @shipment.present?
    end

    private

    # główny flow dla przesyłki
    def main_flow
      [:draft, :created, :dispatched, :sent, :delivered]
    end

    # statusy poza flow
    def alternative_statuses
      [:failed, :cancelled]
    end

    def status_label_i18n(status)
      I18n.t("activerecord.attributes.shipment.statuses.#{status}")
    end

    def current?(status)
      @shipment.aasm.current_state == status.to_sym
    end

    # główny flow statusów
    def main_flow_items
      main_flow.each_with_index.map do |status, index|
        {
          status: status,
          actions: current?(status) ? @shipment.status_actions : []
        }
      end
    end

    # statusy poza flow
    def alternative_items
      alternative_statuses.map do |status|
        {
          status: status,
          actions: current?(status) ? @shipment.status_actions : []
        }
      end
    end

    def status_color(status)
      Shipment.status_color(status.to_s)
    end

    # procent progress line
    def timeline_progress_percent
      current_index = main_flow.index(@shipment.aasm.current_state)
      return 0 unless current_index
      
      ((current_index.to_f / (main_flow.length - 1)) * 100).round(1)
    end

    def circle_state(status, index)
      current_index = main_flow.index(@shipment.aasm.current_state)
      return "incoming" unless current_index
      
      if index < current_index
        "completed"
      elsif index == current_index
        "current"
      else
        "incoming"
      end
    end
    
    def icon_for_state(state)
      case state
      when "completed"
        "ic:baseline-check-circle-outline"
      when "current"
        "ic:baseline-edit-note"
      else
        "ic:baseline-access-time"
      end
    end
  end
end
