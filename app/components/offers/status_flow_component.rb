# frozen_string_literal: true

module Offers
  class StatusFlowComponent < ViewComponent::Base
    def initialize(offer)
      @offer = offer
    end

    def render?
      @offer.present?
    end

    private

    def main_flow
      [:brand_new, :in_preparation, :sent, :accepted, :converted_to_order]
    end

    def alternative_statuses
      [:not_accepted, :rejected]
    end

    def all_statuses
      main_flow + alternative_statuses
    end

    def status_label_i18n(status)
      I18n.t("activerecord.attributes.offer.statuses.#{status}")
    end

    def visible?(status)
      available?(status) || current?(status)
    end

    def current?(status)
      @offer.aasm.current_state == status.to_sym
    end

    def available?(status)
      event = event_for_status(status)
      return false unless event
      
      @offer.send("may_#{event}?")
    end

    # mapowanie ze statusu na event który do niego prowadzi
    def event_for_status(status)
      case status.to_sym
      when :brand_new then :go_back_to_new
      when :in_preparation then :prepare
      when :sent then :send_to_client
      when :accepted then :accept
      when :not_accepted then :mark_as_not_accepted
      when :converted_to_order then :convert_to_order
      when :rejected then :reject
      else nil
      end
    end

    def completed?(status)
      main_flow.include?(status) &&
        main_flow.index(status) < main_flow.index(@offer.aasm.current_state)
    end

    def main_flow_items
      main_flow.each_with_index.map do |status, index|
        {
          status: status,
          event: event_for_status(status),
          available: available?(status),
          color: status_color(status),
          has_arrow: index < main_flow.length - 1
        }
      end
    end

    def alternative_items
      alternative_statuses.map do |status|
        {
          status: status,
          event: event_for_status(status),
          available: available?(status),
          color: status_color(status)
        }
      end
    end

    def status_color(status)
      Offer.status_color(status.to_s)
    end
  end
end

