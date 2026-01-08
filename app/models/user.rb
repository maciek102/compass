class User < ApplicationRecord
  include Destroyable
  include Loggable
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :validatable
  
  # === RELACJE ===
  belongs_to :organization # przynależność do organizacji
  has_many :logs, as: :loggable, dependent: :destroy # historia zmian
  has_many :offers
  
  
  # avatar (zdjęcie profilowe)
  has_one_attached :avatar
  has_one_attached :avatar do |img|
    img.variant :big, resize_to_fit: [600, 600]
    img.variant :medium, resize_to_fit: [450, 450]
    img.variant :small, resize_to_fit: [200, 200]
    img.variant :thumb, resize_to_fit: [50, 50]
  end

  # === ROLE ===
  # Rola wewnątrz organizacji: A (admin), S (standard)
  # Superadmin jest dla całego systemu (is_superadmin = true)
  ROLES = {
    "A" => "admin",
    "S" => "standard"
  }.freeze

  after_create :auto_set_role

  # === SCOPES ===
  scope :superadmins, -> { where(is_superadmin: true) }
  scope :without_superadmins, -> { where(is_superadmin: [false, nil]) }
  scope :admins, -> { where("role_mask = ? OR is_superadmin = ?", "A", true) }
  scope :for_organization, ->(org_id) { where(organization_id: org_id) }
  scope :for_user_organization, ->(user) { where(organization_id: user.organization_id) }


  # === METODY ===
   
  def self.for_user(user)
    if user.superadmin? && user.superadmin_view
      all
    else
      for_organization(user.organization_id).without_superadmins
    end
  end

  # wyświetlanie avatara usera
  def avatar_url(v=:medium)
    avatar.attached? ? rails_representation_url(avatar.variant(v), only_path: true) : 'default_avatar.png'
  end

  # zwraca klucz roli, np. "A"
  def role_key
    role_mask
  end

  # zwraca nazwę roli, np. "admin" (rola organizacji)
  def role
    ROLES[role_mask]
  end

  # czy user jest superadminem (dla całego systemu)
  def superadmin?
    is_superadmin == true
  end

  # czy user ma dostęp admin (superadmin lub admin w organizacji)
  def admin?
    superadmin? || is?("admin")
  end

  def role_name
    if superadmin?
      "superadmin"
    else
      role
    end
  end

  # setter roli, np. set_role(:admin) lub set_role("admin")
  def set_role(r)
    key = ROLES.key(r.to_s)
    raise "Nieznana rola: #{r}" unless key

    update(role_mask: key)
  end

  # sprawdzanie: user.is?(:admin)
  def is?(r)
    role == r.to_s
  end

  # wygodne metody: user.admin? user.standard?
  ROLES.each_value do |r|
    define_method("#{r}?") do
      is?(r)
    end
  end

  # domyślna rola po utworzeniu
  def auto_set_role
    update_column(:role_mask, "S") unless role_mask.present?
  end

  # czy rola jest prawidłowa?
  def valid_role?
    ROLES.key?(role_mask)
  end

  def self.icon
    "user"
  end

  def self.quick_search
    :name_or_email_cont
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    ["confirmation_sent_at", "confirmation_token", "confirmed_at", "created_at", "disabled", "email", "encrypted_password", "id", "id_value", "is_superadmin", "name", "organization_id", "remember_created_at", "reset_password_sent_at", "reset_password_token", "role_mask", "unconfirmed_email", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["avatar_attachment", "avatar_blob", "organization"]
  end

end
