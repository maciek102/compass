module Calculations
  # Serwis do kopiowania aktualnego obliczenia (current) jako nowa wersja
  # Kopiuje wszystkie wiersze i adjustmenty, zachowując strukturę
  #
  # Przykład użycia:
  # Calculations::CopyFromCurrent.call(
  #   calculable: offer,
  #   user: current_user
  # )
  class CopyFromCurrent
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(calculable:, user:)
      @calculable = calculable
      @user = user
      @current_calculation = calculable.calculations.find_by(is_current: true)
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        # Dezaktywuj bieżącą wersję
        @current_calculation.update!(is_current: false)

        # Skopiuj jako nową
        new_calculation = copy_calculation!
        copy_rows!(new_calculation)

        # Przelicz totale
        Calculations::Recalculate.call(calculation: new_calculation)

        new_calculation
      end
    end

    private

    attr_reader :calculable, :user, :current_calculation

    def validate!
      raise Error, "Calculable is required" unless calculable
      raise Error, "User is required" unless user
      raise Error, "No current calculation found" unless current_calculation
      raise Error, "Organization mismatch" if calculable.organization_id != user.organization_id
    end

    def copy_calculation!
      next_number = calculable.calculations.maximum(:number).to_i + 1

      calculable.calculations.create!(
        organization: current_calculation.organization,
        user: user,
        number: next_number,
        is_current: true,
        notes: current_calculation.notes,
        total_net: 0,
        total_vat: 0,
        total_gross: 0,
        total_discounts: 0,
        total_margins: 0
      )
    end

    def copy_rows!(new_calculation)
      current_calculation.calculation_rows.order(:position).each do |row|
        new_row = new_calculation.calculation_rows.create!(
          variant_id: row.variant_id,
          position: row.position,
          name: row.name,
          description: row.description,
          quantity: row.quantity,
          unit: row.unit,
          unit_price: row.unit_price,
          vat_percent: row.vat_percent,
          subtotal: 0,
          total_net: 0,
          total_gross: 0
        )

        # Skopiuj adjustmenty
        row.row_adjustments.each do |adjustment|
          new_row.row_adjustments.create!(
            organization: adjustment.organization,
            adjustment_type: adjustment.adjustment_type,
            name: adjustment.name,
            amount: adjustment.amount,
            is_percentage: adjustment.is_percentage,
            description: adjustment.description
          )
        end
      end
    end
  end
end
