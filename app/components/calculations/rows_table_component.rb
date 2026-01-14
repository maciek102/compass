module Calculations
  
  # === RowsTableComponent ===
  # Komponent do wyświetlania pozycji w wersji (Calculation)
  #
  # locals:
  # calculation: kalkulacja (wersja)
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: calculations_rows/)
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
     
    class RowsTableComponent < ViewComponent::Base
      
      def initialize(calculation:, turbo_id: nil, custom_dir: nil)
        @calculation = calculation
        @rows = calculation.rows
        @turbo_id = turbo_id
        @custom_dir = custom_dir || "calculation_rows/" # domyślna lokalizacja
      end
  
    end

end