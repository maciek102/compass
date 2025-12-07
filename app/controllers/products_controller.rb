class ProductsController < ApplicationController
  load_and_authorize_resource
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu
  
  def index
    @search_url = products_path

    @search = Product.all.ransack(params[:q])
    @list = @products = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
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

  private

  def set_left_menu_context
    @left_menu_context = :products
  end
end
