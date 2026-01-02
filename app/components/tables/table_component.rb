module Tables
  
  # === TableComponent ===
  # Komponent do wyświetlania ZAWARTOŚCI tabeli systemu
  #
  # locals:
  # list: lista obiektów
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: obecna lokalizacja)
  # no_pages: brak paginacji (default: false)
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
     
    class TableComponent < ViewComponent::Base
      
      def initialize(list:, custom_dir:, no_pages: false, turbo_id: nil)
        @list = list
        @custom_dir = custom_dir
        @no_pages = no_pages
        @turbo_id = turbo_id
      end
  
    end

end