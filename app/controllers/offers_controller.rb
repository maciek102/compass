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
      @current_calculation = @offer.current_calculation
      @rows = @current_calculation.rows
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

  def change_status
    new_status = params.dig(:offer, :status)

    if new_status.blank?
      return respond_to do |format|
        format.turbo_stream { render_turbo_stream_response("Błąd: Nie podano statusu", :error) }
      end
    end

    if @offer.transition_to!(new_status)
      message = "Status oferty zmieniony na #{@offer.status_label}"
      respond_to do |format|
        format.turbo_stream { render_turbo_stream_response(message, :notice) }
        format.html { redirect_to @offer, notice: message }
      end
    else
      message = "Nie można zmienić statusu na #{new_status}"
      respond_to do |format|
        format.turbo_stream { render_turbo_stream_response(message, :error) }
        format.html { redirect_to @offer, alert: message }
      end
    end
  end

  def destroy
    @offer.destroy
    redirect_to offers_path, notice: "Oferta została usunięta."
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

  def render_turbo_stream_response(message, type)
    flash[type.to_sym] = message
    render :show, status: :ok
  end
end
