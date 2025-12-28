# === StockMovement ===
# 
# Model reprezentuje pojedynczy ruch magazynowy.
# Jest JEDYNYM źródłem prawdy o stanie magazynowym wariantu.
# Każdy wpis oznacza realną operację:
# - przyjęcie towaru
# - wydanie
# - korektę
# - zwrot
# Stan magazynowy NIE jest edytowany ręcznie
# Stan = suma wszystkich ruchów
# 
# Atrybuty:
# - stock_operation_id:bigint -> operacja magazynowa
# - quantity:integer -> ilość (zawsze dodatnia)
# - movement_type:string -> typ ruchu (delivery, sale, correction, etc.)
# - direction:integer -> 1 (przyjęcie) lub -1 (wydanie)
# - note:text -> opis / powód
# - user_id:bigint -> kto wykonał operację

class StockMovement < ApplicationRecord
  # === RELACJE ===
  belongs_to :stock_operation
  belongs_to :user, optional: true

  # posiada wiele powiązanych itemów
  has_many :stock_movement_items, dependent: :destroy
  has_many :items, through: :stock_movement_items

  has_many_attached :attachments # załączniki

  # === KIERUNEK RUCHU ===
  enum :direction, {
    in: 1, # przyjęcie
    out: -1 # wydanie
  }

  # === TYPY RUCHÓW ===
  enum :movement_type, {
    delivery: "delivery", # dostawa
    return: "return", # zwrot
    sale: "sale", # sprzedaż
  }

  # === WALIDACJE ===
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  validates :movement_type, presence: true
  validates :direction, presence: true

  validate :stock_cannot_go_negative, on: :create

  # === CALLBACKI ===
  after_create_commit :update_variant_stock! # aktualizacja stanu magazynowego



  # === METODY ===
   
  def variant
    stock_operation.variant
  end

  # wartość ruchu z uwzględnieniem kierunku
  def signed_quantity
    quantity * direction.to_i
  end

  def self.icon
    "exchange"
  end

  # tytuł do wyświetlenia
  def title
    "##{id}"
  end

  private

  # nie pozwalamy zejść poniżej zera
  def stock_cannot_go_negative
    return unless out?

    if variant.current_stock + signed_quantity < 0
      errors.add(:quantity, "brak wystarczającego stanu magazynowego")
    end
  end

  # aktualizacja cache stocku na wariancie
  def update_variant_stock!
    variant.recalculate_stock!
  end
end

