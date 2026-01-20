module Shipments
  class Base
    attr_reader :shipment

    def initialize(shipment)
      @shipment = shipment
    end

    def create_parcel
      raise NotImplementedError, "#{self.class} must implement #create_parcel"
    end

    def cancel_parcel
      raise NotImplementedError, "#{self.class} must implement #cancel_parcel"
    end

    def track_parcel
      raise NotImplementedError, "#{self.class} must implement #track_parcel"
    end

    protected

    def handle_response(response)
      if response.success?
        parse_response(response)
      else
        handle_error(response)
      end
    end

    def handle_binary_response(response)
      if response.success?
        response.body
      else
        handle_error(response)
      end
    end

    def parse_response(response)
      JSON.parse(response.body)
    rescue JSON::ParserError => e
      raise ApiError, "Invalid JSON response: #{e.message}"
    end

    def handle_error(response)
      error_message = extract_error_message(response)
      shipment.mark_as_failed!(error_message)
      raise ApiError, error_message
    end

    def extract_error_message(response)
      body = JSON.parse(response.body) rescue {}
      body['error'] || body['message'] || "API Error: #{response.status}"
    end

    class ApiError < StandardError; end
  end
end