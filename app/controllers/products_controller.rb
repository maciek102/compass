class ProductsController < ApplicationController
  load_and_authorize_resource
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu
  
  def index
    @search_url = products_path

    # ustawienie trybów tabeli
    scoped = set_view_mode_scope

    @search = scoped.for_user(current_user).includes(:variants).ransack(params[:q])
    @list = @products = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "variants"
      @variants = @product.variants.page(params[:variants_page])
    elsif @tab == "history"
      @search_url = product_path(@product, tab: "history")
      @search = @product.logs.ransack(params[:q])
      @list = @logs = @search.result.recent.page(params[:logs_page])
    end

    respond_to do |f|
      f.html
      f.js
    end
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
    respond_to do |format|
      if @product.update(product_params)
        flash[:notice] = flash_message(Product, :update)
        format.turbo_stream
        format.html { redirect_to products_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @product.destroy
    redirect_to products_path, notice: "Produkt został usunięty."
  end

  def toggle_variants
    @variants = @product.variants

    respond_to do |f|
      f.js
    end
  end

  private

  def set_left_menu_context
    @left_menu_context = :products
  end

  def set_view_mode_scope
    @view_modes = Views::TableViewMode.new(
      params[:view],
      default: :list,
      modes: {
        list: { label: "Lista", scope: ->(scope) { scope } },
        groups: { label: "Grupy", scope: ->(scope) { scope } }
      }
    )

    @expand_variants = @view_modes.current?(:groups)
    
    @view_modes.apply(Product)
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
