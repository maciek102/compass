class OffersController < ApplicationController
  load_and_authorize_resource

  def index
    @search_url = offers_path

    # ustawienie trybów tabeli
    #scoped = set_view_mode_scope(ProductCategory.for_user(current_user))

    @search = Offer.for_user(current_user).recent.ransack(params[:q])
    @list = @offers = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "calculations"
      @search_url = offer_path(@offer, tab: "calculations")
      @current_calculation = @offer.current_calculation

      @search = @current_calculation.rows.ransack(params[:q])
      @list = @rows = @search.result
    elsif @tab == "history"
      @search_url = offer_path(@offer, tab: "history")
      @search = @offer.logs.ransack(params[:q])
      @list = @logs = @search.result.recent.page(params[:logs_page])
    end

    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @offer.client_id = params[:client_id] if params[:client_id].present?
  end

  def edit
  end

  def create
    @offer = Offer.new(offer_params)
    @offer.user = current_user

    respond_to do |format|
      if @offer.save

        flash[:notice] = flash_message(Offer, :create)

        format.turbo_stream
        format.html { redirect_to @offer, notice: flash[:notice] }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @offer.update(offer_params)

        flash[:notice] = flash_message(Offer, :update)

        format.turbo_stream
        format.html { redirect_to offers_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @offer.destroy
    redirect_to offers_path, notice: "Oferta została usunięta."
  end

  def change_status
    event_name = params.dig(:event)

    if event_name.blank?
      redirect_to request.referrer || offers_path, alert: "Błąd: Nie podano zdarzenia"
      return
    end

    begin
      @offer.aasm.fire!(event_name.to_sym)
      message = "Status oferty zmieniony na #{@offer.status_label}"
      redirect_to request.referrer || offers_path, notice: message
    rescue AASM::InvalidTransition => e
      message = "Nie można wykonać przejścia: #{e.message}"
      redirect_to request.referrer || offers_path, alert: message
    end
  end

  def search
    authorize! :index, Offer
    
    query = params[:q].to_s.strip
    search_params = query.present? ? { number_or_external_number_cont: query } : {}
    search = Offer.for_user(current_user).active.ransack(search_params)
    
    @offers = search.result(distinct: true).recent.limit(30)
    
    respond_to do |format|
      format.json do
        render json: {
          results: @offers.map { |offer| 
            {
              id: offer.id,
              text: offer.number,
              html: render_to_string(
                partial: 'offers/search_result',
                locals: { offer: offer },
                formats: [:html]
              )
            }
          }
        }
      end
    end
  end

  private

  # def set_view_mode_scope(model = ProductCategory)
  #   @view_modes = Views::TableViewModePresenter.new(
  #     params[:view],
  #     default: :roots,
  #     modes: {
  #       roots: { label: "Główne", scope: ->(scope) { scope.roots } },
  #       all: { label: "Wszystkie", scope: ->(scope) { scope.all } }
  #     }
  #   )
  #   @view_modes.apply(model)
  # end

  def offer_params
    params.require(:offer).permit(
      :client_id, :status
    )
  end
end
