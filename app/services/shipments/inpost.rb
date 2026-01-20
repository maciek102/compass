module Shipments
  class Inpost < Base
    if Rails.env.production?
      BASE_URL = "https://api-shipx-pl.easypack24.net"
    else
      BASE_URL = "https://sandbox-api-shipx-pl.easypack24.net"
    end

    def create_parcel
      payload = build_parcel_payload
      response = connection.post("/v1/organizations/#{org_id}/shipments", payload.to_json)
      
      handle_response(response) do |data|
        shipment.mark_as_created!(
          tracking_number: data['tracking_number'],
          external_id: data['id']
        )

        schedule_status_check if data['tracking_number'].blank?
        data
      end
    rescue ApiError => e
      Rails.logger.error("InPost API Error: #{e.message}")
      raise
    end

    def check_status
      return unless shipment.external_id.present?

      response = connection.get("/v1/shipments/#{shipment.external_id}")
      handle_response(response)
    end

    def get_label
      return unless shipment.external_id.present?

      response = connection.get("/v1/shipments/#{shipment.external_id}/label")
      pdf_data = handle_binary_response(response)
      
      if pdf_data.present?
        shipment.label.attach(
          io: StringIO.new(pdf_data),
          filename: "label-#{shipment.external_id}.pdf",
          content_type: 'application/pdf'
        )
      end
      
      pdf_data
    end

    def create_dispatch_order(comment: nil)
      return unless shipment.external_id.present?

      profile = shipment.organization.organization_profile

      unless profile&.sender_data_complete?
        raise ApiError, "Dane nadawcy nie są kompletne. Uzupełnij profil organizacji."
      end

      payload = {
        shipments: [shipment.external_id.to_s],
        comment: comment,
        name: profile.company_name.presence || shipment.organization.try(:name),
        phone: profile.contact_phone,
        email: profile.contact_email,
        address: {
          street: profile.address_street,
          building_number: profile.address_building,
          city: profile.address_city,
          post_code: profile.address_postcode,
          country_code: profile.address_country
        }
      }.compact

      response = connection.post("/v1/organizations/#{org_id}/dispatch_orders", payload.to_json)
      handle_response(response)
    end

    def cancel_parcel
      return unless shipment.external_id.present?

      response = connection.delete("/v1/organizations/#{org_id}/shipments/#{shipment.external_id}")
      handle_response(response) do |data|
        shipment.update!(status: :cancelled)
        data
      end
    end

    def track_parcel
      return unless shipment.external_id.present?

      response = connection.get("/v1/organizations/#{org_id}/shipments/#{shipment.external_id}")
      handle_response(response)
    end

    def get_organization
      response = connection.get("/v1/organizations/#{org_id}")
      handle_response(response)
    end

    private

    def api_key
      shipment.organization.organization_profile.inpost_api_key
    end

    def org_id
      shipment.organization.organization_profile.inpost_organization_id
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.adapter Faraday.default_adapter
        f.headers['Authorization'] = "Bearer #{api_key}"
        f.headers['Content-Type'] = 'application/json'
      end
    end

    def build_parcel_payload
      {
        sender: build_sender,
        receiver: build_receiver,
        parcels: {
          template: 'small'
        },
        service: determine_service,
        reference: shipment.order.number,
        custom_attributes: {
          sending_method: 'dispatch_order',
          target_point: shipment.locker_code
        }.compact
      }
    end

    def build_sender
      profile = shipment.organization.organization_profile
      
      unless profile&.sender_data_complete?
        raise ApiError, "Dane nadawcy nie są kompletne. Uzupełnij profil organizacji."
      end

      {
        company_name: profile.company_name,
        email: profile.contact_email,
        phone: profile.contact_phone,
        address: {
          street: profile.address_street,
          building_number: profile.address_building,
          flat_number: profile.address_apartment,
          city: profile.address_city,
          post_code: profile.address_postcode,
          country_code: profile.address_country
        }
      }
    end

    def build_receiver
      name_parts = shipment.recipient_name.split(' ', 2)
      receiver = {
        first_name: name_parts[0] || shipment.recipient_name,
        last_name: name_parts[1] || '',
        email: shipment.recipient_email,
        phone: shipment.recipient_phone
      }
      
      # Dodaj adres dla przesyłki kurierskiej
      if shipment.delivery_type_courier?
        receiver[:company_name] = shipment.order.client.company_name if shipment.order.client.company_name.present?
        receiver[:address] = {
          street: shipment.address_street,
          building_number: shipment.address_house,
          flat_number: shipment.address_apartment,
          city: shipment.address_city,
          post_code: shipment.address_postcode,
          country_code: shipment.address_country
        }
      end
      
      receiver
    end

    def determine_service
      shipment.delivery_type_locker? ? 'inpost_locker_standard' : 'inpost_courier_standard'
    end

    def handle_response(response)
      if response.success?
        data = parse_response(response)
        block_given? ? yield(data) : data
      else
        super(response)
      end
    end

    def schedule_status_check
      return unless shipment.external_id.present?

      ShipmentStatusJob.set(wait: 1.minute).perform_later(shipment.id)
    end
  end
end