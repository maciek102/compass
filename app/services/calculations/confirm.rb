module Calculations
  # Serwis zatwierdzający kalkulację
  # Po potwierdzeniu kalkulacji generowane są StockOperations dla wszystkich wierszy z wariantami

  class Confirm
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(calculation:, user:)
      @calculation = calculation
      @user = user
      @stock_operations = []
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        create_stock_operations!
        update_order_status! if calculation.calculable.is_a?(Order)
        confirm_calculation!
        log_confirmation!
      end

      @calculation
    end

    private

    attr_reader :calculation, :user, :stock_operations

    def validate!
      raise Error, "Calculation is required" unless calculation
      raise Error, "User is required" unless user
      raise Error, "Calculation already confirmed" if calculation.confirmed_at.present?
      raise Error, "Calculation must be current" unless calculation.is_current
      raise Error, "No rows to confirm" if calculation.calculation_rows.empty?
      
      validate_stock_availability!
    end

    def validate_stock_availability!
      # grupowanie pozycji po wariancie
      rows_by_variant = calculation.calculation_rows.with_variant.group_by(&:variant_id)

      # niewystarczający stan magazynowy
      insufficient_stock = []

      rows_by_variant.each do |variant_id, rows|
        needed_quantity = rows.sum(&:quantity).to_i
        next if needed_quantity <= 0
        
        variant = Variant.find(variant_id)

        # dostępne egzemplarze
        available_items_count = Item.available.of_variant(variant.id).count

        if available_items_count < needed_quantity
          insufficient_stock << {
            variant: variant,
            needed: needed_quantity,
            available: available_items_count,
            missing: needed_quantity - available_items_count
          }
        end
      end

      if insufficient_stock.any?
        error_details = insufficient_stock.map do |info|
          "#{info[:variant].full_name}: potrzeba #{info[:needed]}, dostępne #{info[:available]} (brakuje #{info[:missing]})"
        end.join("; ")
        
        raise Error, "Niewystarczający stan magazynowy: #{error_details}"
      end
    end

    # potwierdzenie kalkulacji
    def confirm_calculation!
      calculation.update!(confirmed_at: Time.current)
    end

    # tworzenie operacji magazynowych na podstawie wierszy kalkulacji
    def create_stock_operations!
      rows_by_variant = calculation.calculation_rows.with_variant.group_by(&:variant_id)

      rows_by_variant.each do |variant_id, rows|
        total_quantity = rows.sum(&:quantity).to_i
        next if total_quantity <= 0
        
        variant = Variant.find(variant_id)

        stock_operation = StockOperation.create!(
          variant: variant,
          calculation: calculation,
          direction: :issue,
          quantity: total_quantity,
          user: user,
          note: "Automatycznie utworzone z kalkulacji ##{calculation.version_number}"
        )

        # rezerwacja fizycznych egzemplarzy (itemów) - domyślnie wg FIFO
        reserve_items_for_operation!(operation: stock_operation, variant: variant, quantity: total_quantity)

        @stock_operations << stock_operation
      end
    end

    # rezerwacja egzemplarzy pod operację magazynową (wg FIFO)
    def reserve_items_for_operation!(operation:, variant:, quantity:)
      scope = Item.available.of_variant(variant.id)

      picker = ItemPicker::Resolver.call(strategy: :fifo, scope: scope)
      result = picker.pick(quantity: quantity)

      # dodatkowa walidacja ilości
      if result.selected_items.size < quantity
        missing = quantity - result.selected_items.size
        raise Error, "Brakuje #{missing} egzemplarzy do rezerwacji dla wariantu #{variant.full_name}"
      end

      # rezerwacja
      result.selected_items.each do |item|
        item.reserve_for!(operation)
      end
    end

    def update_order_status!
      order = calculation.calculable
      order.approve! if order.may_approve?
    end

    def log_confirmation!
      Log.created!(
        loggable: calculation.calculable,
        user: user,
        message: "Potwierdzono kalkulację ##{calculation.version_number}. Utworzono #{@stock_operations.count} operacji magazynowych."
      )
    end
  end
end
