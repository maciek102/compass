class ProductCategoriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu

  def index
    @search_url = product_categories_path

    # ustawienie trybów tabeli
    scoped = set_view_mode_scope

    @search = scoped.includes(:subcategories, :products).ransack(params[:q])
    @list = @product_categories = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @subcategories = @product_category.subcategories.page(params[:subcategories_page])
    @products = @product_category.products.page(params[:products_page])
  end

  def new
    @product_category.product_category_id = params[:parent_id] if params[:parent_id].present?
  end

  def edit
  end

  def create
    @product_category = ProductCategory.new(product_category_params)
    if @product_category.save
      redirect_to @product_category, notice: "Kategoria została utworzona."
    else
      render :new
    end
  end

  def update
    respond_to do |format|
      if @product_category.update(product_category_params)

        scoped = set_view_mode_scope # konieczne extra params w linku do edit, dzięki temu zapamiętujemy tryb widoku kategorii
        @list = @product_categories = scoped.includes(:subcategories, :products).page(params[:page])

        flash[:notice] = flash_message(ProductCategory, :update)

        format.turbo_stream
        format.html { redirect_to product_categories_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @product_category.destroy
    redirect_to product_categories_path, notice: "Kategoria została usunięta."
  end

  private

  def set_left_menu_context
    @left_menu_context = :products
  end

  def set_view_mode_scope
    @view_modes = Views::TableViewMode.new(
      params[:view],
      default: :roots,
      modes: {
        roots: { label: "Główne", scope: ->(scope) { scope.roots } },
        all: { label: "Wszystkie", scope: ->(scope) { scope.all } }
      }
    )
    @view_modes.apply(ProductCategory)
  end

  def product_category_params
    params.require(:product_category).permit(
      :name,
      :description,
      :visible,
      :disabled,
      :slug,
      :product_category_id,
      :position,
      :main_image,
      :code,
      private_images: [],
      subcategories_attributes: [
        :id,
        :name,
        :_destroy
      ]
    )
  end
end
