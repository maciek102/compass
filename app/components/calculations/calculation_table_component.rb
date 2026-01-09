module Calculations
  # === CalculationTableComponent ===
  # Komponent do wyświetlania tabeli z obliczeniami
  #
  # locals:
  # list: lista obiektów
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: obecna lokalizacja)
  # title: tytuł tabeli
  # button: { text: "...", link: _path, class: "...", data_attrs: {...} }
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
  
  class CalculationTableComponent < ViewComponent::Base
    
    def initialize(calculation:, turbo_id: nil)
      @calculation = calculation
      @turbo_id = turbo_id
    end

  end

end