# === OrganizationScoped ===
# Concern dla modeli należących do organizacji.
# Automatycznie ustawia organization_id z bieżącej organizacji (Current.organization)
# oraz dodaje scopes do filtrowania.
#
# Użycie:
#   include OrganizationScoped

module OrganizationScoped
  extend ActiveSupport::Concern

  included do
    # ustawienie organization_id przed walidacją przy tworzeniu rekordu
    before_validation :set_organization_id, on: :create

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
end

