class ClientsController < ApplicationController
  load_and_authorize_resource

  def index
    @search_url = clients_path

    # ustawienie trybów tabeli
    scoped = set_view_mode_scope(Client.for_user(current_user))

    @search = scoped.by_name.ransack(params[:q])
    @list = @clients = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js { render "application/index" }
    end
  end

  def show
    @tab = params[:tab] || "main"

    if @tab == "history"
      @search_url = client_path(@client, tab: "history")
      @search = @client.logs.ransack(params[:q])
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
    @client = Client.new(client_params)

    respond_to do |format|
      if @client.save
        flash[:notice] = flash_message(Client, :create)

        format.turbo_stream
        format.html { redirect_to @client, notice: flash[:notice] }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @client.update(client_params)
        flash[:notice] = flash_message(Client, :update)

        format.turbo_stream
        format.html { redirect_to clients_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_path, notice: "Klient został usunięty."
  end

  private

  def set_view_mode_scope(model = Client)
    @view_modes = Views::TableViewModePresenter.new(
      params[:view],
      default: :active,
      modes: {
        active: { label: "Aktywni", scope: ->(scope) { scope.active } },
        all: { label: "Wszyscy", scope: ->(scope) { scope.all } }
      }
    )
    @view_modes.apply(model)
  end

  def client_params
    params.require(:client).permit(
      :name,
      :email,
      :phone,
      :address,
      :tax_id,
      :registration_number
    )
  end
end
