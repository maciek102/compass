require 'csv'

class ImportJob < ApplicationJob
  queue_as :default

  def perform(import_run_id)
    Rails.logger.info "[ImportJob] Rozpoczynam import dla ImportRun ##{import_run_id}"
    
    # Wyłączamy tenant scope bo job działa w tle bez kontekstu użytkownika
    import_run = ActsAsTenant.without_tenant { ImportRun.find(import_run_id) }
    
    # Ustawiamy tenant dla całej operacji
    ActsAsTenant.with_tenant(import_run.organization) do
      # plik jako stream 
      import_run.source_file.open do |file|
        rows = CSV.parse(file.read.force_encoding('UTF-8'), headers: true, encoding: 'UTF-8')
        
        resource = import_run.resource
        config = ImportExport::ConfigResolver.resolve!(resource)

        import_run.start!(total_rows: rows.size)

        ImportExport::Importer.new(
          config: config,
          organization: import_run.organization,
          rows: rows,
          import_run: import_run
        ).call
      end

      Rails.logger.info "[ImportJob] Importer zakończył pracę"

      import_run.finish_success!
      Rails.logger.info "[ImportJob] Import zakończony sukcesem. Created: #{import_run.created_count}, Updated: #{import_run.updated_count}, Errors: #{import_run.error_count}"

      if import_run.import_errors.any?
        csv_content = CSV.generate(headers: true) do |csv|
          csv << ["line", "message"]
          import_run.import_errors.each do |e|
            csv << [e["line"], e["message"]]
          end
        end

        import_run.result_file.attach(
          io: StringIO.new(csv_content),
          filename: "import_errors_#{Time.zone.now.to_i}.csv",
          content_type: "text/csv"
        )
        Rails.logger.info "[ImportJob] Załączono plik z błędami"
      end
    end
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "[ImportJob] BŁĄD: ImportRun nie znaleziony - #{e.message}"
    Rails.logger.error "[ImportJob] To jest prawdopodobnie stary job z kolejki. Ignoruję."
  rescue => e
    Rails.logger.error "[ImportJob] BŁĄD podczas importu: #{e.class.name}: #{e.message}"
    Rails.logger.error "[ImportJob] Backtrace: #{e.backtrace.first(10).join("\n")}"
    
    begin
      import_run&.finish_failed!
    rescue => error_handling_error
      Rails.logger.error "[ImportJob] Nie mogłem oznaczyć importu jako failed: #{error_handling_error.message}"
    end
    
    raise e
  end
end
