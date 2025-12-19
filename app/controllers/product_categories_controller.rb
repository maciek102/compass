class ProductCategoriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu

  def index
    @search_url = product_categories_path

    # ustawienie trybów tabeli
    scoped = set_view_mode_scope

    @search = scoped.includes(:subcategories, :products).with_aggregated_counts.ransack(params[:q])
    @list = @product_categories = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "subcategories"
      @subcategories = @product_category.subcategories.includes(:subcategories, :products).with_aggregated_counts.page(params[:subcategories_page])
    elsif @tab == "products"
      @products = @product_category.products.page(params[:products_page])
    end

    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @product_category.product_category_id = params[:parent_id] if params[:parent_id].present?
  end

  def edit
  end

  def create
    @product_category = ProductCategory.new(product_category_params)

    respond_to do |format|
      if @product_category.save

        set_turbo_list_after_commit # ustawienie listy kategorii do renderowania w widokach

        flash[:notice] = flash_message(ProductCategory, :create)

        format.turbo_stream
        format.html { redirect_to @product_category, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @product_category.update(product_category_params)

        set_turbo_list_after_commit # ustawienie listy kategorii do renderowania w widokach

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

  # ustawnianie listy kategorii po akcji create/update do renderowania turbo stream w widokach
  def set_turbo_list_after_commit
    # sprawdzamy czy edytujemy z widoku show (podkategorie) czy z index (wszystkie kategorie)
    if params[:subcategory_view].present? && params[:subcategory_view] == "true"
      parent_category = @product_category.parent
      @list = @product_categories = parent_category.subcategories.page(params[:page])
      @parent_category = parent_category
    else
      scoped = set_view_mode_scope # konieczne extra params w linku do edit, dzięki temu zapamiętujemy tryb widoku kategorii
      @list = @product_categories = scoped.includes(:subcategories, :products).page(params[:page])
    end
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
