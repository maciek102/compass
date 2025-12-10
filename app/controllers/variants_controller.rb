class VariantsController < ApplicationController
  before_action :set_product, only: %i[ new create ]
  load_and_authorize_resource :variant
  
  def index
  end

  def show
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

  private

  def set_product
    @product = @variant&.product || Product.find(params[:product_id])
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
