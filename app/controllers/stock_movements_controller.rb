class StockMovementsController < ApplicationController
  load_and_authorize_resource :variant, except: %i[index show]
  load_and_authorize_resource :stock_movement, through: :variant, except: %i[index show]
  load_and_authorize_resource only: %i[index show]

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
    @stock_movement = StockMovement.new(variant: @variant)
  end

  def create_receive
    create_movement(:receive)
  end

  def issue
    @stock_movement = StockMovement.new(variant: @variant)
  end

  def create_issue
    create_movement(:issue)
  end

  def adjust
    @stock_movement = StockMovement.new(variant: @variant)
  end

  def create_adjust
    create_movement(:adjust)
  end

  private

  def set_variant
    @variant = Variant.find(params[:variant_id])
  end

  def create_movement(type)
    service_class = case type
                    when :receive then Stock::Receive
                    when :issue then Stock::Issue
                    when :adjust then Stock::Adjust
                    end

    service_class.call(
      variant: @variant,
      quantity: stock_movement_params[:quantity],
      user: current_user,
      note: stock_movement_params[:note]
    )

    flash[:notice] = flash_message(StockMovement, :created)
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to variant_path(@variant), notice: flash[:notice] }
    end
  rescue Stock::Move::Error => e
    flash.now[:alert] = e.message
    render type
  end

  def stock_movement_params
    params.require(:stock_movement).permit(:quantity, :note, :documents)
  end

  def set_left_menu_context
    @left_menu_context = :warehouse
  end

end
