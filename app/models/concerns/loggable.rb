# służy do automatycznego logowania zmian w modelach, które go dołączają
# zapewnia rejestrowanie tworzenia, aktualizacji i usuwania rekordów
module Loggable
  extend ActiveSupport::Concern

  included do
    after_create  :log_creation
    after_update  :log_update
    before_destroy :log_destruction
  end

  private

  def log_creation
    Log.created!(
      loggable: self,
      user: current_user_from_context,
      message: default_log_message(:create)
    )
  end

  def log_update
    return unless saved_changes.except(:updated_at).present?

    Log.updated!(
      loggable: self,
      user: current_user_from_context,
      message: default_log_message(:update),
      details: saved_changes.except(:updated_at)
    )
  end

  def log_destruction
    Log.destroyed!(
      loggable: self,
      user: current_user_from_context,
      message: default_log_message(:destroy)
    )
  end

  def current_user_from_context
    RequestStore.store[:current_user]
  end

  def default_log_message(action)
    "#{self.class.name} #{loggable_title} został #{action_suffix(action)}"
  end

  # nadpisywalne w modelu (np. dla użycia name/email itp.).
  def loggable_title
    respond_to?(:name) ? name : id
  end

  def action_suffix(action)
    { create: "utworzony", update: "zmieniony", destroy: "usunięty" }[action] || ""
  end
end