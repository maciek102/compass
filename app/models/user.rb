class User < ApplicationRecord
  include Destroyable
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  # === RELACJE ===
  
  
  # avatar (zdjęcie profilowe)
  has_one_attached :avatar
  has_one_attached :avatar do |img|
    img.variant :big, resize_to_fit: [600, 600]
    img.variant :medium, resize_to_fit: [450, 450]
    img.variant :small, resize_to_fit: [200, 200]
    img.variant :thumb, resize_to_fit: [50, 50]
  end

  # === ROLE ===
  ROLES = {
    "A" => "admin",
    "S" => "standard"
  }.freeze

  after_create :auto_set_role



  # === METODY ===

  # wyświetlanie avatara usera
  def avatar_url(v=:medium)
    avatar.attached? ? rails_representation_url(avatar.variant(v), only_path: true) : 'default_avatar.png'
  end

  # zwraca klucz roli, np. "A"
  def role_key
    role_mask
  end

  # zwraca nazwę roli, np. "admin"
  def role
    ROLES[role_mask]
  end

  # alias bardziej opisowy
  def role_name
    role.capitalize
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
      role == r
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
    "users"
  end

end
