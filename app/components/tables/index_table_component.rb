module Tables
  # === IndexTableComponent ===
  # Komponent do wyświetlania podstawowej tabeli systemu
  #
  # locals:
  # list: lista obiektów
  # custom_dir: opcjonalnie folder z partialami _row i _table_header (default: obecna lokalizacja)
  # no_pages: brak paginacji (default: false)
  # title: tytuł tabeli
  # button: { text: "...", link: _path, class: "...", data_attrs: {...} }
  # turbo_id: nazwa/id turbo_frame (opcjonalnie)
  
  class IndexTableComponent < ViewComponent::Base
    
    def initialize(list:, custom_dir: nil, no_pages: false, title: "", button: nil, turbo_id: nil)
      @list = list
      @custom_dir = custom_dir
      @no_pages = no_pages
      @title = title
      @button = button
      @turbo_id = turbo_id
    end

  end

end