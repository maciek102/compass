class ShipmentStatusJob < ApplicationJob
  queue_as :default

  MAX_ATTEMPTS = 5
  RETRY_DELAY = 1.minute

  def perform(shipment_id, attempt = 0)
    shipment = ActsAsTenant.without_tenant { Shipment.find(shipment_id) }
    return if shipment.tracking_number.present?

    ActsAsTenant.with_tenant(shipment.organization) do
      data = shipment.get_status
      tracking_missing = shipment.tracking_number.blank? && (!data.is_a?(Hash) || data['tracking_number'].blank?)

      enqueue_retry(shipment.id, attempt) if tracking_missing
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.warn("ShipmentStatusJob: shipment #{shipment_id} not found: #{e.message}")
  rescue Shipments::Base::ApiError => e
    Rails.logger.error("ShipmentStatusJob API error: #{e.message}")
    raise
  end

  private

  def enqueue_retry(shipment_id, attempt)
    return if attempt >= MAX_ATTEMPTS

    self.class.set(wait: RETRY_DELAY).perform_later(shipment_id, attempt + 1)
  end
end
