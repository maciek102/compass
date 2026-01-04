module ImportExport
  # Wybieranie konfiguracji importu/eksportu na podstawie zasobu.
  
  class ConfigResolver
    RESOURCE_MAP = {
      "product" => ImportExport::Configs::ProductConfig,
      "product_category" => ImportExport::Configs::ProductCategoryConfig
    }.freeze

    def self.resolve!(resource)
      klass = RESOURCE_MAP[resource.to_s]

      raise ArgumentError, "Unknown import resource: #{resource}" unless klass

      klass.new
    end

    def self.allowed_resources
      RESOURCE_MAP.keys
    end
  end
end
