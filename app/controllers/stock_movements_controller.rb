class StockMovementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_stock_operation, only: %i[ receive issue adjust ]

  before_action :set_left_menu_context, only: %i[index show] # ustawieneie kontekstu buildera menu

  def index
    @search_url = stock_movements_path

    @search = StockMovement.for_user(current_user).order(created_at: :desc).ransack(params[:q])
    @list = @stock_movements = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "items"
      @items = @stock_movement.items.page(params[:page])
    elsif @tab == "history"
      @search_url = stock_movement_path(@stock_movement, tab: "history")
      @search = @stock_movement.logs.ransack(params[:q])
      @list = @logs = @search.result.recent.page(params[:logs_page])
    end

    respond_to do |f|
      f.html
      f.js
    end
  end

  def receive
    @stock_movement = StockMovement.new(stock_operation: @stock_operation)

    # przygotowanie tablicy proponowanych itemów do przyjęcia na magazyn
    @proposed_items = set_proposed_items(stock_operation: @stock_operation, quantity: @stock_operation.remaining_quantity)
  end

  def create_receive
    @stock_movement = StockMovement.new(stock_movement_params)

    # mapa numerów seryjnych z formularza
    serial_numbers = params[:proposed_serial_numbers] || {}

    create_movement(:receive, serial_numbers: serial_numbers)
  end

  def issue
    @stock_movement = StockMovement.new(stock_operation: @stock_operation)

    # przygotowanie listy itemów możliwych do wyboru w trakcie wydawania (ItemPicker)
    set_picker_items(
      stock_operation: @stock_operation,
      strategy: :fifo,
      quantity: @stock_operation.remaining_quantity
    )
  end

  def create_issue
    @stock_movement = StockMovement.new(stock_movement_params)
    create_movement(:issue, item_ids: params[:stock_movement][:item_ids] || [])
  end

  def adjust
    @stock_movement = StockMovement.new(stock_operation: @stock_operation)
  end

  def create_adjust
    @stock_movement = StockMovement.new(stock_movement_params)
    create_movement(:adjust)
  end

  # pobranie itemów do wyboru w formularzu wg polityki wydawania ItemPicker
  def set_items_to_issue
    @stock_operation = StockOperation.find(params[:stock_operation_id])
    quantity = params[:quantity].to_i
    strategy = params[:strategy].to_sym

    # przygotowanie listy itemów możliwych do wyboru w trakcie wydawania (ItemPicker)
    set_picker_items(
      stock_operation: @stock_operation,
      strategy: strategy,
      quantity: quantity,
      item_ids: params[:item_ids] || []
    )

    respond_to do |format|
      format.turbo_stream
    end
  end

  # pobranie proponowanych itemów do przyjęcia na magazyn
  def set_items_to_receive
    @stock_operation = StockOperation.find(params[:stock_operation_id])
    quantity = params[:quantity].to_i

    @proposed_items = set_proposed_items(stock_operation: @stock_operation, quantity: quantity)

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # uniwersalna metoda tworząca ruch magazynowy wg podanego typu i realizująca resztę logiki
  def create_movement(type, item_ids: [], serial_numbers: {})
    @stock_operation = @stock_movement.stock_operation
    
    Stock::Operations::Process.call(
      action: type,
      stock_operation: @stock_operation,
      quantity: stock_movement_params[:quantity],
      item_ids: item_ids,
      user: current_user,
      note: stock_movement_params[:note],
      serial_numbers: serial_numbers
    )

    flash[:notice] = flash_message(StockMovement, :created)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to variant_path(@variant), notice: flash[:notice] }
    end
  rescue Stock::Operations::Process::Error => e
    flash.now[:alert] = e.message
    render type
  end

  # przygotowanie listy itemów możliwych do wyboru w trakcie wydawania (ItemPicker)
  def set_picker_items(stock_operation:, strategy:, quantity:, item_ids: [])
    scope = stock_operation.variant.items.in_stock
    picker = ItemPicker::Resolver.call(strategy: strategy, scope: scope, item_ids: item_ids)
    result = picker.pick(quantity: quantity)
    
    @available_items = result.available_items
    @selected_items = result.selected_items
    @selected_ids = result.selected_ids
  end

  # przygotowanie tablicy proponowanych itemów do przyjęcia na magazyn
  def set_proposed_items(stock_operation:, quantity:)
    
    base_number = Item.where(organization_id: current_user.organization_id, variant_id: stock_operation.variant_id).count + 1
    
    Array.new(quantity) do |index|
      item = Item.new(
        variant: stock_operation.variant,
        organization: current_user.organization
      )
      # Dodanie wirtualnych atrybutów dla generacji numeru
      item.define_singleton_method(:serial_number_offset) { index }
      item.define_singleton_method(:serial_number_base) { base_number }
      item
    end
  end

  def stock_movement_params
    params.require(:stock_movement).permit(:quantity, :note, :stock_operation_id, attachments: [], item_ids: [])
  end

  def set_left_menu_context
    @left_menu_context = :warehouse
  end

  def set_stock_operation
    @stock_operation = StockOperation.find(params[:stock_operation_id])
  end

end
