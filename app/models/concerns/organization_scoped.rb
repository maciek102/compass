# === OrganizationScoped ===
# Concern dla modeli należących do organizacji.
# 
# UWAGA: Ten concern został zastąpiony przez acts_as_tenant gem dla scopowania.
# Pozostaje jedynie logika dla id_by_org (unikalne, sekwencyjne ID w obrębie organizacji).
# 
# Wymagania:
# - model musi mieć kolumnę organization_id:integer
# - model musi mieć kolumnę id_by_org:integer (unikalne ID w obrębie organizacji)
# - indeks: index [:organization_id, :id_by_org], unique: true
#
# Użycie (po zadeklarowaniu acts_as_tenant):
#   include Tenantable
#   include OrganizationScoped

module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    # Nadawanie lokalnego ID w obrębie organizacji przy tworzeniu rekordu
    before_create :assign_id_by_org
  end

  private

  # Nadaje lokalne ID w obrębie organizacji (1,2,3... per organization)
  # Thread-safe dzięki PostgreSQL advisory lock
  def assign_id_by_org
    return if id_by_org.present? || organization_id.blank?

    # Używamy advisory lock aby zapobiec race conditions
    # Lock jest lekki i automatycznie zwalniany po transakcji
    self.class.transaction do
      # Unikalny lock ID = hash z nazwy tabeli + organization_id
      lock_id = "#{self.class.table_name}_#{organization_id}".hash.abs
      
      # Pobierz lock (czeka jeśli inny proces ma lock)
      ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(#{lock_id})")
      
      # Teraz bezpiecznie pobierz max ID
      max_id = self.class.unscoped
        .where(organization_id: organization_id)
        .maximum(:id_by_org) || 0
      
      self.id_by_org = max_id + 1
    end
  end
end

