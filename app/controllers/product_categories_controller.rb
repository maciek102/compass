class ProductCategoriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu

  def index
    @search_url = product_categories_path

    # ustawienie trybów tabeli
    scoped = set_view_mode_scope(ProductCategory.for_user(current_user))

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
    elsif @tab == "history"
      @search_url = product_category_path(@product_category, tab: "history")
      @search = @product_category.logs.ransack(params[:q])
      @list = @logs = @search.result.recent.page(params[:logs_page])
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

        flash[:notice] = flash_message(ProductCategory, :create)

        format.turbo_stream
        format.html { redirect_to @product_category, notice: flash[:notice] }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @product_category.update(product_category_params)

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

  def search
    authorize! :index, ProductCategory
    
    query = params[:q].to_s.strip
    search_params = query.present? ? { name_cont: query } : {}
    search = ProductCategory.for_user(current_user).ransack(search_params)
    
    @product_categories = search.result(distinct: true).limit(30)
    
    respond_to do |format|
      format.json do
        render json: {
          results: @product_categories.map { |product_category| 
            {
              id: product_category.id,
              text: product_category.name,
              html: render_to_string(
                partial: 'product_categories/search_result',
                locals: { product_category: product_category },
                formats: [:html]
              )
            }
          }
        }
      end
    end
  end

  private

  def set_left_menu_context
    @left_menu_context = :products
  end

  def set_view_mode_scope(model = ProductCategory)
    @view_modes = Views::TableViewModePresenter.new(
      params[:view],
      default: :roots,
      modes: {
        roots: { label: "Główne", scope: ->(scope) { scope.roots } },
        all: { label: "Wszystkie", scope: ->(scope) { scope.all } }
      }
    )
    @view_modes.apply(model)
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
