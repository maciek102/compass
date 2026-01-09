class CalculationsController < ApplicationController
  before_action :set_calculable, only: :create
  before_action :set_calculation, only: %i[copy set_current]

  ALLOWED_CALCULABLE_TYPES = %w[Offer Order Invoice].freeze

  def create
    authorize! :update, @calculable

    @calculation = Calculations::Create.call(
      calculable: @calculable,
      user: current_user
    )

    flash[:notice] = "Obliczenie zostało utworzone."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target(@calculable) }
    end
  rescue Calculations::Create::Error, Calculations::CopyFromCurrent::Error => e
    flash[:alert] = e.message
    respond_to do |format|
      format.turbo_stream { render action: :create_error }
      format.html { redirect_to redirect_target(@calculable), alert: e.message }
    end
  end


  def copy
    authorize! :update, @calculation.calculable

    calculable = @calculation.calculable
    Calculations::CopyFromCurrent.call(
      calculable: calculable,
      calculation: @calculation,
      user: current_user
    )

    flash[:notice] = "Utworzono kopię obliczenia."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target(calculable) }
    end
  rescue Calculations::CopyFromCurrent::Error => e
    flash[:alert] = e.message
    respond_to do |format|
      format.turbo_stream { render action: :copy_error }
      format.html { redirect_to redirect_target(@calculation.calculable), alert: e.message }
    end
  end

  # PATCH /calculations/:id/set_current
  # Ustawia obliczenie jako aktualne (current)
  def set_current
    authorize! :update, @calculation.calculable

    calculable = @calculation.calculable
    old_version = calculable.calculations.find_by(is_current: true)&.version_number
    calculable.calculations.where(is_current: true).update_all(is_current: false)
    @calculation.update!(is_current: true)

    Log.updated!(
      loggable: calculable,
      user: current_user,
      message: "Zmieniono bieżącą wersję z ##{old_version} na ##{@calculation.version_number}"
    )

    flash[:notice] = "Obliczenie ustawiono jako aktualne."
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target(calculable) }
    end
  rescue StandardError => e
    flash[:alert] = "Błąd: #{e.message}"
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to redirect_target(@calculation.calculable), alert: flash[:alert] }
    end
  end

  private

  def set_calculable
    type = params[:calculable_type]
    id = params[:calculable_id]
    raise Calculations::Create::Error, "Calculable type is required" if type.blank?
    raise Calculations::Create::Error, "Calculable id is required" if id.blank?

    unless ALLOWED_CALCULABLE_TYPES.include?(type)
      raise Calculations::Create::Error, "Unsupported calculable type"
    end

    klass = type.safe_constantize
    raise Calculations::Create::Error, "Invalid calculable type" unless klass

    @calculable = klass.where(organization_id: current_user.organization_id).find(id)
  end

  def set_calculation
    @calculation = Calculation.where(organization_id: current_user.organization_id).find(params[:id])
  end

  def redirect_target(calculable)
    return root_path if calculable.nil?
    return offer_path(calculable, tab: "calculations") if calculable.is_a?(Offer)

    polymorphic_path(calculable)
  end
end
