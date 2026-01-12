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
      @offer.available_transitions.map(&:to_s).include?(status.to_s) ||
        @offer.status.to_s == status.to_s
    end

    def current?(status)
      @offer.status.to_s == status.to_s
    end

    def available?(status)
      @offer.available_transitions.map(&:to_s).include?(status.to_s)
    end

    def completed?(status)
      main_flow.map(&:to_s).include?(status.to_s) &&
        main_flow.map(&:to_s).index(status.to_s) < main_flow.map(&:to_s).index(@offer.status.to_s)
    end

    def main_flow_items
      main_flow.each_with_index.map do |status, index|
        {
          status: status,
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

