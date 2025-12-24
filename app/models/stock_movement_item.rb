# === StockMovementItem ===
#
# Łączy ruch magazynowy z konkretnym egzemplarzem (itemem)
# Pozwala dokładnie śledzić:
# - które itemy zostały przyjęte / wydane / skorygowane
#
# Atrybuty:
# - stock_movement_id
# - item_id
#
class StockMovementItem < ApplicationRecord
  belongs_to :stock_movement
  belongs_to :item
end