module Dashboards
  class WarehouseQuery
    def initialize(user:)
      @user = user
    end

    # Statystyki magazynu
    def stock_stats
      {
        total_items: total_items_count,
        in_stock: in_stock_count,
        reserved: reserved_count,
        damaged: damaged_count
      }
    end

    def todays_movements
      StockMovement.where("created_at >= ?", Time.current.beginning_of_day)
    end

    def todays_operations
      StockOperation.where(created_at: Time.zone.today.all_day)
    end

    # oczekujące operacje magazynowe
    def open_operations
      StockOperation.opened
    end

    # w trakcie realizacji 
    def in_realization_operations
      StockOperation.in_realization
    end

    private

    def total_items_count
      Item.count
    end

    def in_stock_count
      Item.where(status: Item.statuses[:in_stock]).count
    end

    def reserved_count
      Item.where(status: Item.statuses[:reserved]).count
    end

    def damaged_count
      Item.where(status: Item.statuses[:damaged]).count
    end
  end
end
