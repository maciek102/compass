class ItemsController < ApplicationController
  load_and_authorize_resource
  
  def index
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "movements"
      @stock_movements = @item.stock_movements.page(params[:page])
    elsif @tab == "history"
      @search_url = item_path(@item, tab: "history")
      @search = @item.logs.ransack(params[:q])
      @list = @logs = @search.result.recent.page(params[:logs_page])
    end

    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
  end
end
