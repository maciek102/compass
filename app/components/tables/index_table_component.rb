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
  # filters: true/false (domyślne filtry z application/filters)
  # custom_filters: { partial: "...", locals: {...} } # opcjonalne własne filtry
  
  class IndexTableComponent < ViewComponent::Base
    
    def initialize(list:, 
      custom_dir: nil, 
      no_pages: false, 
      title: "", 
      button: nil, 
      turbo_id: nil, 
      filters: false, 
      custom_filters: nil)

      @list = list
      @custom_dir = custom_dir
      @no_pages = no_pages
      @title = title
      @button = button
      @turbo_id = turbo_id
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
      !@list.nil?
    end

  end

end