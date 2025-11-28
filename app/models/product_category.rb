# === ProductCategory ===
#
# Model reprezentuje kategorię produktów w systemie. Pozwala na:
# - grupowanie produktów w kategorie i podkategorie
# - hierarchiczne drzewo kategorii
# - zarządzanie widocznością i kolejnością wyświetlania
#
# Atrybuty:
# - name:string -> nazwa kategorii
# - description:text -> opis kategorii
# - slug:string -> unikalny, przyjazny URL, np. "elektronika"
# - position:integer -> kolejność wyświetlania
# - product_category_id:bigint -> referencja do rodzica dla podkategorii
# - visible:boolean -> czy kategoria jest widoczna dla użytkowników
# - disabled:boolean -> soft-delete, dezaktywacja kategorii
# - main_image:active_storage -> zdjęcia kategorii
# - private_images:active_storage -> zdjęcia robocze

class ProductCategory < ApplicationRecord
  include Destroyable

  # relacja hierarchiczna
  belongs_to :parent_category, class_name: "ProductCategory", foreign_key: "product_category_id", optional: true
  has_many :subcategories, class_name: "ProductCategory", foreign_key: "product_category_id", dependent: :destroy

  # === RELACJE ===
  # produkty należące do kategorii
  has_many :products, dependent: :destroy

  has_one_attached :main_image # główne zdjęcie kategorii
  has_many_attached :private_images # zdjęcia robocze / prywatne

  # === WALIDACJE ===
  validates :name, presence: true
  validates :slug, uniqueness: true, allow_blank: true

  # === SCOPE ===
  scope :active, -> { where(disabled: false) } # niezarchiwizowane
  scope :visible, -> { where(visible: true, disabled: false) }

  # === CALLBACKI ===
  before_validation :generate_slug, if: -> { slug.blank? && name.present? } # generacja slug

  private

  # generacja slug ("Smartfony i tablety" -> "smartfony-i-tablety")
  def generate_slug
    self.slug = name.parameterize
  end
end
