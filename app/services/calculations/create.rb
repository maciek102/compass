module Calculations
  # Serwis do tworzenia nowej wersji obliczenia dla dokumentu (Offer/Order/Invoice)
  # Automatycznie ustawia is_current na false dla poprzedniej wersji
  #
  # Przykład użycia:
  # Calculations::Create.call(
  #   calculable: offer,
  #   user: current_user,
  #   rows_attributes: [{ variant_id: 1, quantity: 10, unit_price: 100 }]
  # )
  class Create
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(calculable:, user:, rows_attributes: [], notes: nil)
      @calculable = calculable
      @user = user
      @rows_attributes = rows_attributes
      @notes = notes
      @organization = calculable.organization
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        deactivate_current_calculation!
        create_calculation!
      end
    end

    private

    attr_reader :calculable, :user, :rows_attributes, :notes, :organization, :calculation

    def validate!
      raise Error, "Calculable is required" unless calculable
      raise Error, "User is required" unless user
      raise Error, "Organization mismatch" if calculable.organization_id != user.organization_id
    end

    def deactivate_current_calculation!
      calculable.calculations.where(is_current: true).update_all(is_current: false)
    end

    def create_calculation!
      @calculation = calculable.calculations.create!(
        organization: organization,
        user: user,
        is_current: true,
        total_net: 0,
        total_vat: 0,
        total_gross: 0,
        total_discounts: 0,
        total_margins: 0
      )

      # Dodaj wiersze jeśli zostały przekazane
      rows_attributes.each do |row_attrs|
        Calculations::Rows::Create.call(
          calculation: @calculation,
          **row_attrs.symbolize_keys
        )
      end

      # Przelicz totale
      Calculations::Recalculate.call(calculation: @calculation)

      log_creation!

      @calculation
    end

    def log_creation!
      Log.created!(
        loggable: calculable,
        user: user,
        message: "Utworzono wersję ##{@calculation.version_number}"
      )
    end
  end
end
