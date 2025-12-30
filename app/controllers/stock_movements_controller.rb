class StockMovementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_stock_operation, only: %i[ receive issue adjust ]

  before_action :set_left_menu_context, only: %i[index show] # ustawieneie kontekstu buildera menu

  def index
    @search_url = stock_movements_path

    @search = StockMovement.for_user(current_user).ransack(params[:q])
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
  end

  def create_receive
    @stock_movement = StockMovement.new(stock_movement_params)
    create_movement(:receive)
  end

  def issue
    @stock_movement = StockMovement.new(stock_operation: @stock_operation)

    get_picker_items(
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
  def prepare_items
    @stock_operation = StockOperation.find(params[:stock_operation_id])
    quantity = params[:quantity].to_i
    strategy = params[:strategy].to_sym

    get_picker_items(
      stock_operation: @stock_operation,
      strategy: strategy,
      quantity: quantity,
      item_ids: params[:item_ids] || []
    )

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def create_movement(type, item_ids: [])
    @stock_operation = @stock_movement.stock_operation
    
    Stock::Operations::Process.call(
      action: type,
      stock_operation: @stock_operation,
      quantity: stock_movement_params[:quantity],
      item_ids: item_ids,
      user: current_user,
      note: stock_movement_params[:note]
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

  def get_picker_items(stock_operation:, strategy:, quantity:, item_ids: [])
    scope = stock_operation.variant.items.in_stock
    picker = ItemPicker::Resolver.call(strategy: strategy, scope: scope, item_ids: item_ids)
    result = picker.pick(quantity: quantity)
    
    @available_items = result.available_items
    @selected_items = result.selected_items
    @selected_ids = result.selected_ids
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
