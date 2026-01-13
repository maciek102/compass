# === Client ===
#
# Model reprezentuje klienta w systemie wieloorganizacyjnym (multi-tenant).
# Obsługuje zarówno klientów biznesowych (B2B) jak i indywidualnych (B2C).
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator w ramach organizacji
# - name:string -> nazwa klienta / firmy
# - email:string -> email kontaktowy
# - phone:string -> telefon
# - address:string -> adres klienta
# - tax_id:string -> NIP / VAT ID
# - registration_number:string -> REGON lub inne
# - disabled:boolean -> soft-delete / deaktywacja

class Client < ApplicationRecord
  include Tenantable
  include OrganizationScoped
  include Destroyable
  include Loggable

  # === RELACJE ===
  has_many :offers
  has_many :orders
  
  # === WALIDACJE ===
  validates :name, presence: true
  validates :email, presence: true
  validates :email, uniqueness: { scope: :organization_id }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, message: "jest nieprawidłowy" }
  validates :phone, format: { with: /\A[\d\s+\-\(\)]+\z/, message: "jest nieprawidłowy" }, allow_blank: true
  validates :tax_id, uniqueness: { scope: :organization_id, allow_blank: true }

  # === CALLBACKI ===
  

  # === SCOPES ===
  scope :active, -> { where(disabled: false) }
  scope :inactive, -> { where(disabled: true) }
  scope :by_name, -> { order(:name) }
  scope :recent, -> { order(created_at: :desc) }



  # === METODY ===
  def self.for_user(user)
    all
  end

  def self.quick_search
    :name_or_email_cont
  end

  # Zwraca pełny adres
  def full_address
    address
  end

  # Status klienta dla wyświetlania
  def status_label
    disabled? ? "Wyłączony" : "Aktywny"
  end

  def self.icon
    "users"
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    ["address", "created_at", "disabled", "email", "id", "id_by_org", "name", "organization_id", "phone", "registration_number", "tax_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["logs", "organization"]
  end
end
