# === OrganizationScoped ===
# Concern dla modeli należących do organizacji.
# Automatycznie ustawia organization_id z bieżącej organizacji (Current.organization)
# oraz dodaje scopes do filtrowania.
# 
# Wymagania:
# - model musi mieć kolumnę organization_id:integer
# - model musi mieć kolumnę id_by_org:integer (unikalne ID w obrębie organizacji)
# - Current.organization musi być ustawione (np. w ApplicationController)
#
# Użycie:
#   include OrganizationScoped

module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    # ustawienie organization_id przed walidacją przy tworzeniu rekordu
    before_validation :set_organization_id, on: :create
    before_create :assign_id_by_org

    # scopes do filtrowania według organizacji
    scope :for_organization, ->(org_id) { where(organization_id: org_id) }
    scope :for_user_organization, ->(user) { where(organization_id: user.organization_id) }
  end

  private

  def set_organization_id
    if organization_id.blank? && Current.organization.present?
      self.organization_id = Current.organization.id
    end
  end

  # Nadaje lokalne ID w obrębie organizacji (1,2,3... per organization)
  def assign_id_by_org
    return if id_by_org.present? || organization_id.blank?

    max_id = self.class.where(organization_id: organization_id).maximum(:id_by_org) || 0
    self.id_by_org = max_id + 1
  end
end

