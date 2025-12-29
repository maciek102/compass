module Views

  # === FiltersDisplayService ===
  #
  # Serwis odpowiedzialny za wyświetlanie i zarządzanie filtrami dla różnych modeli.
  # Centralizuje logikę formatowania wartości filtrów oraz generowania linków do usuwania.
  #
  # Użycie:
  #   service = FiltersDisplayService.new(model_class, params)
  #   service.display_value(field_name, value)
  #   service.remove_filter_link(field_name)
  #   service.active_filters

  class FiltersDisplayService
    attr_reader :model_class, :params

    def initialize(model_class, params)
      @model_class = model_class
      @params = params
    end

    # Zwraca hash aktywnych filtrów z params[:q]
    def active_filters
      return {} unless params[:q].respond_to?(:slice)
      
      allowed_filters = model_class.const_get(:FILTERS) rescue []
      
      # symbole na stringi dla slice
      params[:q].slice(*allowed_filters.map(&:to_s)).reject { |k, v| v.blank? }
    end

    # Formatuje wartość filtra do wyświetlenia
    def display_value(field_name, value)
      return if value.blank?

      formatter = find_formatter(field_name)
      formatter ? formatter.call(field_name, value) : default_format(field_name, value)
    end

    # Generuje parametry do linku usuwającego dany filtr
    def remove_filter_link(field_name)
      allowed_filters = model_class.const_get(:FILTERS) rescue []
      # Permit params z uwzględnieniem wszystkich dozwolonych filtrów
      permitted = params.permit(q: allowed_filters.map(&:to_s))
      # Usuń wybrany filtr
      new_q = permitted[:q]&.except(field_name.to_s) || {}
      permitted.merge(q: new_q)
    end

    private

    # Znajduje odpowiedni formatter dla danego pola
    def find_formatter(field_name)
      formatter_method = "format_#{field_name}"
      return method(formatter_method) if respond_to?(formatter_method, true)

      # Sprawdź wzorce
      PATTERN_FORMATTERS.each do |pattern, formatter|
        return formatter if field_name.to_s.match?(pattern)
      end

      nil
    end

    # Formattery dla konkretnych wzorców pól
    PATTERN_FORMATTERS = {
      /_id_eq$/ => ->(field, value) { Views::FiltersDisplayService.format_relation_eq(field, value) },
      /_id_in$/ => ->(field, value) { Views::FiltersDisplayService.format_relation_in(field, value) },
      /_cont$/ => ->(field, value) { Views::FiltersDisplayService.format_contains(field, value) },
      /_eq$/ => ->(field, value) { Views::FiltersDisplayService.format_equals(field, value) },
      /_gteq$/ => ->(field, value) { Views::FiltersDisplayService.format_greater_equal(field, value) },
      /_lteq$/ => ->(field, value) { Views::FiltersDisplayService.format_less_equal(field, value) }
    }.freeze

    # === FORMATTERY WZORCÓW ===

    def self.format_relation_eq(field_name, value)
      relation_name = field_name.to_s.sub(/_id_eq$/, '')
      find_and_display_relation(relation_name, value)
    end

    def self.format_relation_in(field_name, value)
      relation_name = field_name.to_s.sub(/_id_in$/, '')
      ids = Array.wrap(value).reject(&:blank?)
      find_and_display_relation(relation_name, ids, multiple: true)
    end

    def self.format_contains(field_name, value)
      field_label = field_name.to_s.sub(/_cont$/, '').humanize
      "#{field_label} zawiera: #{value}"
    end

    def self.format_equals(field_name, value)
      field_label = field_name.to_s.sub(/_eq$/, '').humanize
      "#{field_label}: #{value.to_s.humanize}"
    end

    def self.format_greater_equal(field_name, value)
      field_label = field_name.to_s.sub(/_gteq$/, '').humanize
      "#{field_label} ≥ #{value}"
    end

    def self.format_less_equal(field_name, value)
      field_label = field_name.to_s.sub(/_lteq$/, '').humanize
      "#{field_label} ≤ #{value}"
    end

    # Znajduje i wyświetla nazwę powiązanego modelu
    def self.find_and_display_relation(relation_name, value, multiple: false)
      relation_class = relation_name.classify.safe_constantize
      return "#{relation_name.humanize}: #{value}" if relation_class.nil?

      if multiple
        ids = Array.wrap(value)
        return if ids.empty?
        relation_class.where(id: ids).pluck(:name).join(", ")
      else
        record = relation_class.find_by(id: value)
        record&.name || "#{relation_name.humanize}: #{value}"
      end
    end

    # Domyślny format dla nieznanych typów
    def default_format(field_name, value)
      "#{field_name.to_s.humanize}: #{value}"
    end
  end
end