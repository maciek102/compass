class ProductsController < ApplicationController
  load_and_authorize_resource
  
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
end
