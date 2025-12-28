class StockMovementsController < ApplicationController
  load_and_authorize_resource
  before_action :set_stock_operation, only: %i[ receive issue adjust ]

  before_action :set_left_menu_context, only: %i[index show] # ustawieneie kontekstu buildera menu

  def index
    @search_url = stock_movements_path

    @search = StockMovement.all.ransack(params[:q])
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
  end

  def create_issue
    @stock_movement = StockMovement.new(stock_movement_params)
    create_movement(:issue)
  end

  def adjust
    @stock_movement = StockMovement.new(stock_operation: @stock_operation)
  end

  def create_adjust
    @stock_movement = StockMovement.new(stock_movement_params)
    create_movement(:adjust)
  end

  private

  def create_movement(type)
    @stock_operation = @stock_movement.stock_operation
    
    Stock::Operations::Process.call(
      action: type,
      stock_operation: @stock_operation,
      quantity: stock_movement_params[:quantity],
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

  def stock_movement_params
    params.require(:stock_movement).permit(:quantity, :note, :documents, :stock_operation_id)
  end

  def set_left_menu_context
    @left_menu_context = :warehouse
  end

  def set_stock_operation
    @stock_operation = StockOperation.find(params[:stock_operation_id])
  end

end
