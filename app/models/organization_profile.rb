class OrganizationProfile < ApplicationRecord
  include Tenantable

  validates :organization, presence: true, uniqueness: true
  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true


  def full_address
    [
      address_street,
      address_building,
      address_apartment,
      address_city,
      address_postcode,
      address_country
    ].compact.reject(&:blank?).join(', ')
  end

  def sender_data_complete?
    company_name.present? &&
      contact_email.present? &&
      contact_phone.present? &&
      address_street.present? &&
      address_building.present? &&
      address_city.present? &&
      address_postcode.present? &&
      address_country.present?
  end
end
