class CalculationRowsController < ApplicationController
  load_and_authorize_resource :calculation
  load_and_authorize_resource :calculation_row, through: :calculation
  before_action :check_calculation_editable, only: %i[new create edit update destroy]

  def new
    @mode = params[:type]&.downcase || "custom"
  end

  def edit
  end
  
  # POST /calculations/:calculation_id/calculation_rows
  def create
    @calculation_row = Calculations::Rows::Create.call(
      calculation: @calculation,
      **calculation_row_params.to_h.symbolize_keys
    )

    flash[:notice] = "Wiersz został dodany."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target }
    end
  rescue Calculations::Rows::Create::Error => e
    flash[:alert] = e.message
    respond_to do |format|
      format.turbo_stream { render action: :create_error }
      format.html { redirect_to redirect_target, alert: e.message }
    end
  end

  # PATCH/PUT /calculations/:calculation_id/calculation_rows/:id
  def update
    Calculations::Rows::Update.call(
      row: @calculation_row,
      **calculation_row_params.to_h.symbolize_keys
    )

    flash[:notice] = "Wiersz został zaktualizowany."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target }
    end
  rescue Calculations::Rows::Update::Error => e
    flash[:alert] = e.message
    respond_to do |format|
      format.turbo_stream { render action: :update_error }
      format.html { redirect_to redirect_target, alert: e.message }
    end
  end

  # DELETE /calculations/:calculation_id/calculation_rows/:id
  def destroy
    authorize! :update, @calculation.calculable

    Calculations::Rows::Destroy.call(row: @calculation_row)

    flash[:notice] = "Wiersz został usunięty."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target }
    end
  rescue Calculations::Rows::Destroy::Error => e
    flash[:alert] = e.message
    respond_to do |format|
      format.turbo_stream { render action: :destroy_error }
      format.html { redirect_to redirect_target, alert: e.message }
    end
  end

  private

  def check_calculation_editable
    if @calculation.confirmed?
      flash[:alert] = "Nie można edytować potwierdzonej kalkulacji."
      redirect_to redirect_target
    end
  end

  def set_calculation
    @calculation = Calculation.where(organization_id: current_user.organization_id).find(params[:calculation_id])
  end

  def set_calculation_row
    @calculation_row = @calculation.calculation_rows.find(params[:id])
  end

  def redirect_target
    calculable = @calculation.calculable
    return root_path if calculable.nil?
    return offer_path(calculable, tab: "calculations") if calculable.is_a?(Offer)

    polymorphic_path(calculable)
  end

  def calculation_row_params
    params.require(:calculation_row).permit(
      :variant_id,
      :name,
      :description,
      :quantity,
      :unit,
      :unit_price,
      :vat_percent
    )
  end
end
