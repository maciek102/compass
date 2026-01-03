class VariantsController < ApplicationController
  before_action :set_product, only: %i[ new create ]
  load_and_authorize_resource :variant
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu
  
  def index
    @search_url = variants_path

    @search = Variant.for_user(current_user).includes(:product).ransack(params[:q])
    @list = @variants = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    case @tab
    when "main"
      
    when "items"
      @items = @variant.items.page(params[:page])
    when "operations"
      @search_url = variant_path(@variant, tab: "operations")
      @search = @variant.stock_movements.ransack(params[:q])
      @list = @stock_movements = @search.result.page(params[:operations_page])
    when "history"
      @search_url = variant_path(@variant, tab: "history")
      @search = @variant.logs.ransack(params[:q])
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
    @variant = @product.variants.new(variant_params)
    if @variant.save
      redirect_to product_path(@product), notice: "Wariant został utworzony."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @variant.update(variant_params)
      redirect_to product_path(@product), notice: "Wariant został zaktualizowany."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end

  def scanner
    @left_menu_context = nil
  end

  private

  def set_product
    @product = @variant&.product || Product.find(params[:product_id])
  end

  def set_left_menu_context
    # context - potrzebny żeby lewe menu wiedziało, który kontekst (produktowy/magazynowy) jest aktywny dla wariantów - DO EWENTUALNEJ POPRAWY, nie miałem lepszego pomysłu
    @left_menu_context = params[:context]&.to_sym || :products
  end

  def variant_params
    # przystosowanie niestandardowych atrybutów z formlarza na json
    ca_keys = params[:variant].delete(:custom_attributes_keys) || []
    ca_values = params[:variant].delete(:custom_attributes_values) || []
    custom_attrs = ca_keys.zip(ca_values).reject { |key, _| key.blank? }.to_h.compact_blank
    params[:variant][:custom_attributes] = custom_attrs.presence || {}

    params.require(:variant).permit(
      :name, :sku, :price, :stock, :weight, :ean, :location, :note,
      custom_attributes: {}
    )
  end
end
