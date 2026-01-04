require 'ostruct'

module ImportExport
  module Configs
    # Klasa bazowa dla konfiguracji importu/eksportu
    # Definiuje podstawowe metody i struktury danych do definiowania modelu, kluczy identyfikujących, atrybutów oraz relacji.
    # Każda konkretna konfiguracja (np. ProductConfig) powinna dziedziczyć po tej klasie i implementować swoje specyficzne ustawienia.
    
    class Base
      attr_reader :relations, :attribute_mappers

      def initialize
        @identify_by = []
        @attributes = []
        @relations = []
        @attribute_mappers = {}
      end

      def model(klass = nil)
        return @model if klass.nil?
        @model = klass
      end

      def identify_by(*keys)
        return @identify_by if keys.empty?
        Rails.logger.debug "[CONFIG] identify_by called with: #{keys.inspect}"
        @identify_by = keys
        Rails.logger.debug "[CONFIG] @identify_by set to: #{@identify_by.inspect}"
      end

      def attributes(*attrs)
        return @attributes if attrs.empty?
        Rails.logger.debug "[CONFIG] attributes called with: #{attrs.inspect}"
        @attributes = attrs
        Rails.logger.debug "[CONFIG] @attributes set to: #{@attributes.inspect}"
      end

      def belongs_to(name, column:, lookup:)
        @relations << OpenStruct.new(
          name: name,
          column: column,
          lookup: lookup
        )
      end

      def map_attribute(attribute_name, &block)
        @attribute_mappers[attribute_name] = block
      end
    end
  end
end
