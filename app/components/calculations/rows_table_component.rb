module Calculations
  
  # === RowsTableComponent ===
  # Komponent do wyświetlania pozycji w wersji (Calculation)
  #
  # locals:
  # rows: lista pozycji
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: obecna lokalizacja)
  # no_pages: brak paginacji (default: false)
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
     
    class RowsTableComponent < ViewComponent::Base
      
      def initialize(calculation:, turbo_id: nil)
        @calculation = calculation
        @rows = calculation.rows
        @turbo_id = turbo_id
      end
  
    end

end