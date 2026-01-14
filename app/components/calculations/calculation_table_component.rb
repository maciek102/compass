module Calculations
  # === CalculationTableComponent ===
  # Komponent do wyświetlania tabeli z obliczeniami
  #
  # locals:
  # list: lista obiektów
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: calculations_rows/)
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
  
  class CalculationTableComponent < ViewComponent::Base
    
    def initialize(calculation:, turbo_id: nil, custom_dir: nil)
      @calculation = calculation
      @turbo_id = turbo_id
      @custom_dir = custom_dir
    end

  end

end