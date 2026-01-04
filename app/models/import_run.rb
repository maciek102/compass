# === ImportRun ===
#
# Model reprezentujący pojedyncze uruchomienie importu danych do systemu.
# Służy do śledzenia stanu i wyników procesu importu.
#
# Atrybuty:
# - organization_id: ID organizacji, do której należy import
# - user_id: ID użytkownika, który zainicjował import
# - status: status importu (pending, running, success, failed)
# - total_rows: całkowita liczba wierszy do zaimportowania
# - processed_rows: liczba już przetworzonych wierszy
# - created_count: liczba pomyślnie utworzonych rekordów
# - updated_count: liczba pomyślnie zaktualizowanych rekordów
# - error_count: liczba wierszy, które spowodowały błędy podczas importu
# - errors: szczegóły błędów w formacie JSON
# - file_name: nazwa pliku importu
# - meta: dodatkowe metadane dotyczące importu w formacie JSON

class ImportRun < ApplicationRecord
  include OrganizationScoped

  belongs_to :organization
  belongs_to :user

  has_one_attached :source_file # plik wysłany przez użytkownika
  has_one_attached :result_file # raport / CSV z błędami

  enum :status, {
    pending: 0,
    running: 1,
    success: 2,
    failed: 3
  }

  def self.for_user(user)
    default_scope = for_organization(user.organization_id)
    default_scope
  end

  def self.icon
    "download"
  end

  def title
    "##{id_by_org}"
  end

  def start!(total_rows:)
    update!(
      status: :running,
      total_rows: total_rows,
      processed_rows: 0,
      created_count: 0,
      updated_count: 0,
      error_count: 0,
      import_errors: []
    )
  end

  def increment_processed!
    increment!(:processed_rows)
  end

  def increment_created!
    increment!(:created_count)
  end

  def increment_updated!
    increment!(:updated_count)
  end

  def add_error(line, message)
    self.import_errors ||= []
    self.import_errors << { line: line, message: message }
    self.error_count = import_errors.size
    save!
  end

  def finish_success!
    update!(status: :success)
  end

  def finish_failed!
    update!(status: :failed)
  end
end
