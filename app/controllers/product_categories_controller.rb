class ProductCategoriesController < ApplicationController
  load_and_authorize_resource
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu

  def index
    @search_url = product_categories_path

    @search = ProductCategory.all.ransack(params[:q])
    @list = @product_categories = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
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
    if @product_category.update(product_category_params)
      redirect_to @product_category, notice: "Kategoria została zaktualizowana."
    else
      render :edit
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
      private_images: [],
      subcategories_attributes: [
        :id,
        :name,
        :_destroy
      ]
    )
  end
end
