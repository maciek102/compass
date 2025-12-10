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
    @variants = @product.variants.page(params[:variants_page])
  end

  def new
    @product.product_category_id = params[:category_id] if params[:category_id].present?
  end

  def edit
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Produkt został utworzony."
    else
      render :new
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Produkt został zaktualizowany."
    else
      render :edit
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Produkt został usunięty."
  end

  private

  def set_left_menu_context
    @left_menu_context = :products
  end

  def product_params
    params.require(:product).permit(
      :name,
      :sku,
      :product_category_id,
      :status,
      :slug,
      :description,
      :notes,
      :main_image,
      :code,
      gallery: [],
      private_images: [],
      main_description: []
    )
  end
end
