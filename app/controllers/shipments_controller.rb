class ShipmentsController < ApplicationController
  load_and_authorize_resource
  before_action :set_order, only: %i[new create]

  def new
    @shipment = @order.build_shipment(
      provider: :inpost,
      delivery_type: :locker,
      recipient_name: @order.client.name,
      recipient_email: @order.client.email,
      recipient_phone: @order.client.phone,
      address_street: @order.client.street,
      address_house: @order.client.building_number,
      address_apartment: @order.client.apartment_number,
      address_city: @order.client.city,
      address_postcode: @order.client.postcode,
      address_country: @order.client.country_code || 'PL'
    )
  end

  def create
    @shipment = @order.build_shipment(shipment_params)

    if @shipment.save
      redirect_to order_path(@order, tab: 'delivery'), notice: 'Dane dostawy zostały zapisane.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def edit
  end

  def update
    if @shipment.update(shipment_params)
      redirect_to order_path(@shipment.order, tab: 'delivery'), notice: 'Dane dostawy zostały zaktualizowane.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    order = @shipment.order
    @shipment.destroy
    redirect_to order_path(order, tab: 'delivery'), notice: 'Dostawa została usunięta.'
  end

  def create_parcel
    begin
      @shipment.create_parcel!
      redirect_to order_path(@shipment.order, tab: 'delivery'), notice: 'Przesyłka została utworzona u kuriera.'
    rescue Shipments::Base::ApiError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    rescue StandardError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    end
  end

  def cancel_parcel
    begin
      @shipment.cancel_parcel!
      redirect_to order_path(@shipment.order, tab: 'delivery'), notice: 'Przesyłka została anulowana.'
    rescue Shipments::Base::ApiError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    rescue StandardError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    end
  end

  def track
    begin
      tracking_data = @shipment.track_parcel
      redirect_to order_path(@shipment.order, tab: 'delivery'), notice: "Status: #{tracking_data['status']}"
    rescue Shipments::Base::ApiError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    rescue StandardError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    end
  end

  def get_status
    begin
      status_data = @shipment.get_status
      redirect_to order_path(@shipment.order, tab: 'delivery'), notice: "Status przesyłki: #{status_data['status']}"
    rescue Shipments::Base::ApiError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    rescue StandardError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    end
  end

  def create_dispatch
    begin
      data = @shipment.create_dispatch!(comment: params[:comment])
      msg = "Zlecenie odbioru utworzone (status: #{data['status']})"
      redirect_to order_path(@shipment.order, tab: 'delivery'), notice: msg
    rescue Shipments::Base::ApiError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    rescue StandardError => e
      redirect_to order_path(@shipment.order, tab: 'delivery'), alert: "Błąd: #{e.message}"
    end
  end

  private

  def set_order
    @order = Order.find(params[:order_id])
  end

  def set_shipment
    @shipment = Shipment.find(params[:id])
  end

  def shipment_params
    params.require(:shipment).permit(
      :provider,
      :delivery_type,
      :locker_code,
      :recipient_name,
      :recipient_email,
      :recipient_phone,
      :address_street,
      :address_house,
      :address_apartment,
      :address_city,
      :address_postcode,
      :address_country
    )
  end
end
