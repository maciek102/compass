# === Product ===
#
# Model reprezentuje produkt jako główny byt katalogowy.
# "Wzorzec" produktu, z którego mogą wynikać warianty (np. Koszulka - rozm. S,M,L) oraz fizyczne itemy (np. konkretna Koszulka - rozm. S #123).
# Pełni rolę:
# - nadrzędnego opisu produktu (nazwa, opis, kategoria)
# - kontenera dla wariantów (np. rozmiar, kolor)
# - źródła danych (zdjęcia, notatki, tagi)
# - miejsca integracji ze slugami, SEO oraz filtrowaniem
#
# Atrybuty:
# - name:string -> nazwa produktu
# - description:text -> opis produktu
# - main_description:rich_text -> główny duży opis
# - notes:text -> notatki wewnętrzne
# - sku:string -> kod globalny produktu (opcjonalny, warianty mogą mieć własne)
# - slug:string -> przyjazny adres URL
# - product_category_id:bigint -> kategoria
# - status:integer -> stan publikacji / widoczności
# - disabled:boolean -> soft-delete
# - main_image:active_storage -> główne zdjęcie produktu
# - gallery:active_storage -> dodatkowe zdjęcia
# - private_images:active_storage -> zdjęcia robocze

class Product < ApplicationRecord
  include Destroyable

  # === RELACJE ===
  # kategoria produktu
  belongs_to :product_category

  # warianty produktu
  has_many :variants, dependent: :destroy

  has_one_attached :main_image # główne zdjęcie
  has_many_attached :gallery # dodatkowe zdjęcia
  has_many_attached :private_images # zdjęcia robocze

  has_rich_text :main_description # główny, duży opis rich text

  # === STATUSY ===
  enum :status, {
    draft: 0, # w trakcie tworzenia
    available: 1, # dostępny w sprzedaży
  }

  # === WALIDACJE ===
  validates :name, presence: true
  validates :slug, uniqueness: true, allow_blank: true
  validates :sku, uniqueness: true, allow_blank: true

  # === SCOPE ===
  scope :active, -> { where(disabled: false) } # niezarchiwizowane
  scope :available_for_sale, -> { where(disabled: false, status: statuses[:available]) } # widoczne, aktywne dla klienta
  scope :with_category, ->(category_id) { where(product_category_id: category_id) }

  # === CALLBACKI ===
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }



  # === METODY ===
  
  def self.icon
    "dropbox"
  end

  # Zwraca liczbę wszystkich fizycznych itemów we wszystkich wariantach
  def total_stock
    variants.sum { |v| v.stock.to_i }
  end

  private

  # generuje slug ("Smartfony i tablety" -> "smartfony-i-tablety")
  def generate_slug
    self.slug = name.parameterize
  end
end
