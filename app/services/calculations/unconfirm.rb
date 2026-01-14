module Calculations
  # Serwis do cofania potwierdzenia kalkulacji
  # Usuwa powiązane operacje magazynowe i przywraca możliwość edycji kalkulacji
  #
  # Przykład użycia:
  # Calculations::Unconfirm.call(
  #   calculation: calculation,
  #   user: current_user
  # )
  # 
  # TODO --- wstępna wersja napisana przez czat, na razie po prostu usuwa wszystko
  class Unconfirm
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(calculation:, user:)
      @calculation = calculation
      @user = user
      @organization = calculation.organization
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        destroy_stock_operations!
        unconfirm_calculation!
        revert_order_status! if calculation.calculable.is_a?(Order)
        log_unconfirmation!
      end

      @calculation
    end

    private

    attr_reader :calculation, :user, :organization

    def validate!
      raise Error, "Calculation is required" unless calculation
      raise Error, "User is required" unless user
      raise Error, "Organization mismatch" if calculation.organization_id != user.organization_id
      raise Error, "Calculation not confirmed" unless calculation.confirmed?
      raise Error, "Cannot unconfirm - stock operations already have movements" if has_movements?
    end

    def has_movements?
      calculation.stock_operations.any? { |op| op.stock_movements.any? }
    end

    def destroy_stock_operations!
      # zwolnienie rezerwacji
      calculation.stock_operations.find_each do |op|
        Item.where(
          organization_id: calculation.organization_id,
          variant_id: op.variant_id,
          reserved_stock_operation_id: op.id,
          status: Item.statuses[:reserved]
        ).find_each(&:unreserve!)
      end

      calculation.stock_operations.destroy_all
    end

    def unconfirm_calculation!
      calculation.update!(confirmed_at: nil)
    end

    def revert_order_status!
      order = calculation.calculable
      if order.approved? && !has_movements?
        order.update!(status: :in_preparation)
      end
    end

    def log_unconfirmation!
      Log.created!(
        loggable: calculation.calculable,
        user: user,
        message: "Cofnięto potwierdzenie kalkulacji ##{calculation.version_number}"
      )
    end
  end
end
