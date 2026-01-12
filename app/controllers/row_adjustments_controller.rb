class RowAdjustmentsController < ApplicationController
  load_and_authorize_resource :calculation
  load_and_authorize_resource :calculation_row, through: :calculation
  load_and_authorize_resource :row_adjustment, through: :calculation_row, except: [:index, :create]

  before_action :set_adjustment_type, only: [:index, :create]

  # GET /calculations/:calculation_id/calculation_rows/:calculation_row_id/row_adjustments
  def index
    @row_adjustments = @calculation_row.row_adjustments.send(@adjustment_type)
  end

  # POST /calculations/:calculation_id/calculation_rows/:calculation_row_id/row_adjustments
  def create
    service_class = @adjustment_type == "discount" ? 
      Calculations::Rows::Adjustments::AddDiscount : 
      Calculations::Rows::Adjustments::AddMargin

    @row_adjustment = service_class.call(
      row: @calculation_row,
      amount: row_adjustment_params[:amount],
      is_percentage: row_adjustment_params[:is_percentage] == "true",
      description: row_adjustment_params[:description]
    )

    @row_adjustments = @calculation_row.row_adjustments.send(@adjustment_type)
    flash[:notice] = "#{@adjustment_type == 'discount' ? 'Rabat' : 'Marża'} został dodany."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calculation_path(@calculation) }
    end
  rescue Calculations::Rows::Adjustments::AddDiscount::Error,
         Calculations::Rows::Adjustments::AddMargin::Error => e
    flash[:alert] = e.message
    @row_adjustments = @calculation_row.row_adjustments.send(@adjustment_type)
    respond_to do |format|
      format.turbo_stream { render action: :create_error }
      format.html { redirect_to calculation_path(@calculation), alert: e.message }
    end
  end

  # DELETE /calculations/:calculation_id/calculation_rows/:calculation_row_id/row_adjustments/:id
  def destroy
    @row_adjustment = RowAdjustment.find(params[:id])
    adjustment_type = @row_adjustment.adjustment_type

    Calculations::Rows::Adjustments::Remove.call(adjustment: @row_adjustment)

    @row_adjustments = @calculation_row.row_adjustments.send(adjustment_type)
    @adjustment_type = adjustment_type
    flash[:notice] = "#{adjustment_type == 'discount' ? 'Rabat' : 'Marża'} został usunięty."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to calculation_path(@calculation) }
    end
  rescue Calculations::Rows::Adjustments::Remove::Error => e
    flash[:alert] = e.message
    @adjustment_type = adjustment_type
    @row_adjustments = @calculation_row.row_adjustments.send(adjustment_type)
    respond_to do |format|
      format.turbo_stream { render action: :destroy_error }
      format.html { redirect_to calculation_path(@calculation), alert: e.message }
    end
  end

  private

  def set_adjustment_type
    @adjustment_type = params[:type] == "discount" ? "discount" : "margin"
  end

  def row_adjustment_params
    params.require(:row_adjustment).permit(:description, :amount, :is_percentage)
  end
end
