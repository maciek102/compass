module Calculations
  # === CalculationTableComponent ===
  # Komponent do wyświetlania tabeli z obliczeniami
  #
  # locals:
  # list: lista obiektów
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: calculations_rows/)
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
  # filters: true/false (domyślne filtry z application/filters)
  # custom_filters: { partial: "...", locals: {...} } # opcjonalne własne filtry
  
  class CalculationTableComponent < ViewComponent::Base
    
    def initialize(calculation:, turbo_id: nil, custom_dir: nil, filters: false, custom_filters: nil)
      @calculation = calculation
      @turbo_id = turbo_id
      @custom_dir = custom_dir
      @filters = filters
      @custom_filters = custom_filters
    end

    private

    def filters_partial_path
      "application/filters"
    end

    def custom_filters_locals
      (@custom_filters && @custom_filters[:locals]) || {}
    end

    def render?
      !@calculation.calculation_rows.nil?
    end

  end

end