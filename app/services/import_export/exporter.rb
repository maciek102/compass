module ImportExport
  # Eksporter danych do formatu CSV na podstawie podanej konfiguracji i zakresu rekordów.
  # Używa konfiguracji do określenia, które atrybuty i relacje mają być eksportowane.
  # Generuje plik CSV z nagłówkami i danymi zgodnie z konfiguracją.
  # 
  # Przykład użycia:
  # config = ImportExport::Configs::ProductConfig.new
  # csv = ImportExport::Exporter.new(
  #   config: config,
  #   scope: current_organization.products
  # ).call

  
  class Exporter
    def initialize(config:, scope:)
      @config = config
      @scope = scope
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << headers

        @scope.find_each do |record|
          csv << row(record)
        end
      end
    end

    private

    def headers
      @config.attributes.map(&:to_s) +
        @config.relations.map { |r| r.column.to_s }
    end

    def row(record)
      @config.attributes.map { |a| record.public_send(a) } +
        @config.relations.map { |r| record.public_send(r.name)&.code }
    end
  end
end
