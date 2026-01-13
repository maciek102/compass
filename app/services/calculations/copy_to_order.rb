module Calculations
  # Serwis do kopiowania aktualnego obliczenia z oferty do zamówienia
  # Duplikuje wszystkie wiersze i adjustmenty
  #
  # Przykład użycia:
  # Calculations::CopyToOrder.call(
  #   order: order,
  #   offer: offer,
  #   user: current_user
  # )
  class CopyToOrder
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(order:, offer:, user: nil)
      @order = order
      @offer = offer
      @user = user
      @source_calculation = offer.calculations.find_by(is_current: true)
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        new_calculation = copy_calculation!
        copy_rows!(new_calculation)

        # Przelicz totale
        Calculations::Recalculate.call(calculation: new_calculation)

        log_copy!(new_calculation)

        new_calculation
      end
    end

    private

    attr_reader :order, :offer, :user, :source_calculation

    def validate!
      raise Error, "Order is required" unless order
      raise Error, "Offer is required" unless offer
      raise Error, "No current calculation found in offer" unless source_calculation
      raise Error, "Offer must have calculations" if offer.calculations.empty?
      raise Error, "Organization mismatch" if offer.organization_id != order.organization_id
    end

    def copy_calculation!
      order.calculations.create!(
        organization: source_calculation.organization,
        user: user,
        is_current: true,
        total_net: 0,
        total_vat: 0,
        total_gross: 0,
        total_discounts: 0,
        total_margins: 0
      )
    end

    def copy_rows!(new_calculation)
      source_calculation.calculation_rows.order(:position).each do |row|
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
            amount: adjustment.amount,
            is_percentage: adjustment.is_percentage,
            description: adjustment.description
          )
        end
      end
    end

    def log_copy!(new_calculation)
      Log.created!(
        loggable: order,
        user: user,
        message: "Skopiowano obliczenie z oferty ##{offer.number}",
        details: { offer_id: offer.id, calculation_id: new_calculation.id }
      )
    end
  end
end
