class OrdersController < ApplicationController
  load_and_authorize_resource

  def index
    @search_url = orders_path

    # ustawienie trybów tabeli
    #scoped = set_view_mode_scope(ProductCategory.for_user(current_user))

    @search = Order.for_user(current_user).recent.ransack(params[:q])
    @list = @orders = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "calculations"
      @current_calculation = @order.current_calculation
      @rows = @current_calculation.rows
    elsif @tab == "stock"
      @current_calculation = @order.current_calculation
      if @current_calculation&.confirmed?
        @stock_operations = @current_calculation.stock_operations.includes(:variant, :stock_movements)
      else
        @stock_operations = []
      end
    elsif @tab == "history"
      @search_url = order_path(@order, tab: "history")
      @search = @order.logs.ransack(params[:q])
      @list = @logs = @search.result.recent.page(params[:logs_page])
    end

    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @offer = Offer.find_by(id: params[:offer_id]) if params[:offer_id].present?
    @order.offer_id = @offer.id if @offer
    @order.client_id = @offer.client_id if @offer
  end

  def edit
  end

  def create
    @order = Order.new(order_params)
    @order.user = current_user

    respond_to do |format|
      if @order.save

        flash[:notice] = flash_message(Order, :create)

        format.turbo_stream
        format.html { redirect_to @order, notice: flash[:notice] }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @order.update(order_params)

        flash[:notice] = flash_message(Order, :update)

        format.turbo_stream
        format.html { redirect_to orders_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @order.destroy
    redirect_to orders_path, notice: "Zamówienie zostało usunięte."
  end

  def change_status
    event_name = params.dig(:event)

    if event_name.blank?
      redirect_to request.referrer || orders_path, alert: "Błąd: Nie podano zdarzenia"
      return
    end

    begin
      @order.aasm.fire!(event_name.to_sym)
      message = "Status zamówienia zmieniony na #{@order.status_label}"
      redirect_to request.referrer || orders_path, notice: message
    rescue AASM::InvalidTransition => e
      message = "Nie można wykonać przejścia: #{e.message}"
      redirect_to request.referrer || orders_path, alert: message
    end
  end

  private

  # def set_view_mode_scope(model = ProductCategory)
  #   @view_modes = Views::TableViewModePresenter.new(
  #     params[:view],
  #     default: :roots,
  #     modes: {
  #       roots: { label: "Główne", scope: ->(scope) { scope.roots } },
  #       all: { label: "Wszystkie", scope: ->(scope) { scope.all } }
  #     }
  #   )
  #   @view_modes.apply(model)
  # end

  def order_params
    params.require(:order).permit(
      :client_id,
      :offer_id,
      :number,
      :external_number,
      :status
    )
  end

  def render_turbo_stream_response(message, type)
    flash[type.to_sym] = message
    render :show, status: :ok
  end
end
