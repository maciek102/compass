class VariantsController < ApplicationController
  before_action :set_product, only: %i[ new create ]
  load_and_authorize_resource :variant, except: %i[ search ]
  before_action :set_left_menu_context # ustawieneie kontekstu buildera menu
  
  def index
    @search_url = variants_path

    @search = Variant.for_user(current_user).includes(:product, :items).ransack(params[:q])
    @list = @variants = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def stock_index
    @left_menu_context = :warehouse

    @search_url = stock_index_variants_path

    # ustawienie trybów tabeli
    scoped = set_view_mode_scope(Variant.for_user(current_user))

    @search = scoped.includes(:product, :items).ransack(params[:q])
    @list = @variants = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js { render "application/index" }
    end
  end

  def show
    @tab = params[:tab] || "main"

    case @tab
    when "main"
      
    when "items"
      # ustawienie trybów tabeli
      @search_url = variant_path(@variant, tab: "items")

      scoped = set_view_mode_scope_items_tab(@variant.items)
      @search = scoped.ransack(params[:q])
      @list = @items = scoped.page(params[:page])
    when "operations"
      @search_url = variant_path(@variant, tab: "operations")
      @search = @variant.stock_operations.recent.ransack(params[:q])
      @list = @stock_operations = @search.result.page(params[:operations_page])
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
      redirect_to @variant, notice: "Wariant został utworzony."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @variant.update(variant_params)
      redirect_to @variant, notice: "Wariant został zaktualizowany."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
  end

  def scanner
    @left_menu_context = nil
  end

  def scanner_result
    barcode = params[:barcode].to_s.strip

    if barcode.blank?
      render :scanner, alert: "Błąd: pusty kod"
      return
    end

    @variant = Variant.for_user(current_user).find_by(ean: barcode)

    if @variant.nil?
      @error_message = "Nie znaleziono wariantu z kodem: #{barcode}"
      render :scanner
      return
    end

    respond_to do |f|
      f.js
    end
  end

  def toggle_stock_items
    @items = @variant.items.available

    respond_to do |f|
      f.js
    end
  end

  def toggle_reserved_items
    @items = @variant.items.reserved

    respond_to do |f|
      f.js
    end
  end

  def search
    authorize! :index, Variant
    query = params[:q].to_s.strip
    search_params = query.present? ? { name_or_sku_or_product_name_cont: query } : {}
    search = Variant.for_user(current_user).includes(:product).ransack(search_params)
    @variants = search.result(distinct: true).limit(30)

    respond_to do |format|
      format.json do
        render json: {
          results: @variants.map { |variant|
            {
              id: variant.id,
              text: variant.name,
              html: render_to_string(
                partial: 'variants/search_result',
                locals: { variant: variant },
                formats: [:html]
              )
            }
          }
        }
      end
    end
  end

  private

  def set_product
    @product = @variant&.product || Product.find(params[:product_id])
  end

  def set_left_menu_context
    # context - potrzebny żeby lewe menu wiedziało, który kontekst (produktowy/magazynowy) jest aktywny dla wariantów - DO EWENTUALNEJ POPRAWY, nie miałem lepszego pomysłu
    @left_menu_context = params[:context]&.to_sym || :products
  end

  def set_view_mode_scope(model = Variant)
    @view_modes = Views::TableViewModePresenter.new(
      params[:view],
      default: :list,
      modes: {
        list: { label: "Lista", scope: ->(scope) { scope } },
        stock: { label: "Stan", scope: ->(scope) { scope } },
        reserved: { label: "Rezerwacje", scope: ->(scope) { scope } }
      }
    )

    @expand_stock = @view_modes.current?(:stock)
    @expand_reserved = @view_modes.current?(:reserved)
    
    @view_modes.apply(model)
  end

  def set_view_mode_scope_items_tab(model)
    @view_modes = Views::TableViewModePresenter.new(
      params[:view],
      default: :available,
      modes: {
        available: { label: "Dostępne", scope: ->(scope) { scope.available } },
        reserved: { label: "Zarezerwowane", scope: ->(scope) { scope.reserved } },
        sold: { label: "Wydane", scope: ->(scope) { scope.issued } },
        all: { label: "Wszystkie", scope: ->(scope) { scope } }
      }
    )

    @view_modes.apply(model)
  end

  def variant_params
    # przystosowanie niestandardowych atrybutów z formlarza na json
    ca_keys = params[:variant].delete(:custom_attributes_keys) || []
    ca_values = params[:variant].delete(:custom_attributes_values) || []
    custom_attrs = ca_keys.zip(ca_values).reject { |key, _| key.blank? }.to_h.compact_blank
    params[:variant][:custom_attributes] = custom_attrs.presence || {}

    params.require(:variant).permit(
      :name, :sku, :price, :weight, :ean, :location, :note,
      custom_attributes: {}
    )
  end
end
