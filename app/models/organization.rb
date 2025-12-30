# === ORGANIZATION ===
# 
# !!! KLUCZOWY MODEL W SYSTEMIE !!!
# 
# Model reprezentujący organizację w systemie wieloorganizacyjnym (multi-tenant).
# Pozwala na:
# - separację danych między różnymi organizacjami
# - zarządzanie użytkownikami i zasobami w kontekście organizacji
# Atrybuty:
# - name:string -> nazwa organizacji
# - description:text -> opis organizacji
# - active:boolean -> czy organizacja jest aktywna
# - launched:boolean -> czy organizacja jest wydana do użytku

class Organization < ApplicationRecord
  include Destroyable
  include Loggable

  # === RELACJE ===
  has_many :users, dependent: :destroy
  has_many :product_categories, dependent: :destroy
  has_many :products, dependent: :destroy
  has_many :variants, dependent: :destroy
  has_many :items, dependent: :destroy
  has_many :stock_operations, dependent: :destroy
  has_many :stock_movements, dependent: :destroy

  has_many :logs, as: :loggable, dependent: :destroy # historia zmian
  
  # === WALIDACJE ===
  validates :name, presence: true, uniqueness: true
  
  # === SCOPES ===
  scope :active, -> { where(active: true) }
  scope :launched, -> { where(launched: true) }


  # === METODY ===

  def self.icon
    "building"
  end

  def usable?
    active && launched
  end
  
  def self.ransackable_attributes(auth_object = nil)
    ["active", "created_at", "description", "id", "launched", "name", "updated_at"]
  end
end
