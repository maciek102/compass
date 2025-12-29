class StockOperationsController < ApplicationController
  load_and_authorize_resource

  before_action :set_left_menu_context, only: %i[index show]
  before_action :set_filters, only: %i[index]

  def index
    @search_url = stock_operations_path

    @search = StockOperation.all.order(created_at: :desc).ransack(params[:q])
    @list = @stock_operations = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "main"
      @stock_movements = @stock_operation.stock_movements.order(created_at: :desc).page(params[:page])
    end

    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @stock_operation = StockOperation.new(variant_id: params[:variant_id]) if params[:variant_id].present?
  end

  def create
    @stock_operation = StockOperation.new(stock_operation_params)

    respond_to do |format|
      if @stock_operation.save

        flash[:notice] = flash_message(StockOperation, :create)
        format.turbo_stream
        format.html { redirect_to @stock_operation, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @stock_operation.update(stock_operation_params)

        flash[:notice] = flash_message(StockOperation, :update)
        format.turbo_stream
        format.html { redirect_to stock_operations_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def stock_operation_params
    params.require(:stock_operation).permit(:quantity, :direction, :variant_id)
  end

  def set_left_menu_context
    @left_menu_context = :warehouse
  end

  def set_filters
    @filters_service = Views::FiltersDisplayService.new(StockOperation, params)
  end
end