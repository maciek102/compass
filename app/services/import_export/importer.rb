module ImportExport
  # Importer danych z formatu CSV na podstawie podanej konfiguracji i wierszy danych.
  # Używa konfiguracji do określenia, jak znaleźć lub utworzyć rekordy oraz jakie atrybuty i relacje przypisać.
  # Generuje błędy importu z informacją o linii w przypadku problemów podczas procesu importu.
  #
  # Przykład użycia:
  # config = ImportExport::Configs::ProductConfig.new
  # ImportExport::Importer.new(
  #   config: config,
  #   organization: current_organization,
  #   rows: CSV.parse(file.read, headers: true)
  # ).call
  
  class Importer
    def initialize(import_run:, config:, rows:, organization: nil)
      @import_run = import_run
      @organization = organization || import_run.organization
      @config = config
      @rows = rows
    end

    def call
      Rails.logger.info "[IMPORTER] Rozpoczynam import #{@rows.size} wierszy dla modelu #{@config.model.name}"
      Rails.logger.info "[IMPORTER] Organization ID: #{@organization.id}"
      Rails.logger.info "[IMPORTER] Identify by: #{@config.identify_by.inspect}"
      Rails.logger.info "[IMPORTER] Attributes: #{@config.attributes.inspect}"
      Rails.logger.info "[IMPORTER] Relations: #{@config.relations.map(&:name).inspect}"
      Rails.logger.info "[IMPORTER] Attribute mappers: #{@config.attribute_mappers.keys.inspect}"
      
      ActiveRecord::Base.transaction do
        @rows.each_with_index do |row, index|
          import_row(row, index + 2) # +2 bo header + index 0
        end
      end
      
      Rails.logger.info "[IMPORTER] Import zakończony"
    end

    private

    attr_reader :import_run

    def import_row(row, line)
      Rails.logger.debug "[IMPORTER] Przetwarzanie linii #{line}: #{row.to_h.inspect}"
      
      import_run.increment_processed!

      record = find_or_initialize(row)
      was_new = record.new_record?
      Rails.logger.debug "[IMPORTER] Linia #{line}: #{was_new ? 'Nowy rekord' : 'Istniejący rekord'} - #{record.inspect}"

      assign_attributes(record, row)
      assign_relations(record, row)

      record.save!
      Rails.logger.debug "[IMPORTER] Linia #{line}: Zapisano pomyślnie"

      was_new ? import_run.increment_created! : import_run.increment_updated!
    rescue => e
      Rails.logger.error "[IMPORTER] BŁĄD na linii #{line}: #{e.class.name}: #{e.message}"
      Rails.logger.error "[IMPORTER] Dane wiersza: #{row.to_h.inspect}"
      import_run.add_error(line, e.message)
    end


    def find_or_initialize(row)
      @config.model.find_or_initialize_by(
        organization_id: @organization.id,
        **identify_hash(row)
      )
    end

    def identify_hash(row)
      @config.identify_by
        .reject { |k| k == :organization_id }
        .index_with { |k| row[k.to_s] }
    end

    def assign_attributes(record, row)
      @config.attributes.each do |attr|
        next unless row.key?(attr.to_s)
        
        # Sprawdzenie czy jest custom mapper dla tego atrybutu
        if @config.attribute_mappers.key?(attr.to_sym)
          Rails.logger.debug "[IMPORTER] Mapowanie atrybutu #{attr} przez custom mapper"
          @config.attribute_mappers[attr.to_sym].call(row[attr.to_s], record, @organization)
        else
          Rails.logger.debug "[IMPORTER] Przypisanie atrybutu #{attr} = #{row[attr.to_s]}"
          record.public_send("#{attr}=", row[attr.to_s])
        end
      end
    end

    def assign_relations(record, row)
      @config.relations.each do |rel|
        value = row[rel.column.to_s]
        next if value.blank?

        associated = rel.lookup.call(@organization, value)
        record.public_send("#{rel.name}=", associated)
      end
    end
  end
end
