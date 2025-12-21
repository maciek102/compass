# === Log ===
#
# Model służący do rejestrowania działań (logów) w systemie.
# Reprezentuje wpisy logów dotyczące różnych modeli (loggable) w systemie.
#
# Pozwala na:
# - śledzenie działań użytkowników i systemu
# - przechowywanie dodatkowych informacji o zmianach
#
# Atrybuty:
# - loggable_type:string -> typ powiązanego modelu (polimorficzne)
# - loggable_id:bigint -> ID powiązanego modelu (polimorficzne)
# - user_id:bigint -> ID użytkownika wykonującego akcję (opcjonalne)
# - action:string -> rodzaj akcji (np. create, update, destroy)
# - message:text -> opis akcji
# - details:jsonb -> dodatkowe szczegóły dotyczące akcji

class Log < ApplicationRecord
  belongs_to :loggable, polymorphic: true
  belongs_to :user, optional: true

  # === AKCJE (nagłówki) ===
  enum :action, {
    create: "create",
    update: "update",
    destroy: "destroy",
    status: "status",
    assign: "assign"
  }, prefix: true

  validates :action, presence: true

  # === SCOPE ===
  scope :recent, -> { order(created_at: :desc) }
  scope :for_action, ->(action) { where(action: action) }
  scope :by_user, ->(user) { where(user: user) }


  # === METODY ===

  def self.log!(loggable:, action:, user: nil, message: nil, details: {})
    create!(
      loggable: loggable,
      action: action.to_s,
      message: message.presence,
      details: details.presence,
      user: user
    )
  end

  def self.created!(loggable:, user: nil, message: nil, details: {})
    log!(
      loggable: loggable,
      action: :create,
      user: user,
      message: message,
      details: details
    )
  end

  def self.updated!(loggable:, user: nil, message: nil, details: {})
    log!(
      loggable: loggable,
      action: :update,
      user: user,
      message: message,
      details: details
    )
  end

  def self.destroyed!(loggable:, user: nil, message: nil, details: {})
    log!(
      loggable: loggable,
      action: :destroy,
      user: user,
      message: message,
      details: details
    )
  end

  def action_title
    I18n.t("log_actions.#{action}", default: action.humanize)
  end

  def author_name
    user&.name || "System"
  end

  def formatted_message
    message.presence || action_title
  end

  def changes?
    details.present?
  end

  def self.quick_search
    :message_or_user_name_or_action_cont
  end

  private

  def self.ransackable_attributes(auth_object = nil)
    ["action", "created_at", "details", "id", "loggable_id", "loggable_type", "message", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["loggable", "user"]
  end
end
