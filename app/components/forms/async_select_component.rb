module Forms
  # === AsyncSelectComponent ===
  # 
  # Komponent select z lazy loadingiem danych
  # Użytkownik wpisuje min. N znaków, a wyniki są wyświetlane w konfigurowalnym formacie (partial)
  # 
  # użycie:
  #   = render Forms::AsyncSelectComponent.new(
  #     form: f,
  #     field: :client_id,
  #     url: search_clients_path,
  #     selected_id: @calculation.client_id,
  #     selected_text: @calculation.client&.name
  #   )
  # 
  # bez form buildera:
  #   = render Forms::AsyncSelectComponent.new(
  #     name: "calculation[client_id]",
  #     url: search_clients_path,
  #     placeholder: "Wyszukaj klienta...",
  #     selected_id: 123,
  #     selected_text: "Example Client"
  #   )
  # 
  # endpoint API powinien zwracać JSON w takim formacie
  # {
  #   "results": [
  #     {
  #       "id": 1,
  #       "text": "Tekst do wyświetlenia",
  #       "html": "<div>Custom HTML dla opcji</div>" (opcjonalnie) (najlepiej spersonalizowany partial)
  #     }
  #   ]
  # }
  
  class AsyncSelectComponent < ViewComponent::Base

    def initialize(
      form: nil,
      field: nil,
      name: nil,
      url:,
      placeholder: I18n.t("async_select.placeholder", min_chars: 3),
      min_chars: 3,
      selected_id: nil,
      selected_text: nil,
      delay: 300,
      label: nil,
      required: false,
      html_options: {}
    )

      @form = form
      @field = field
      @name = name
      @url = url
      @placeholder = placeholder
      @min_chars = min_chars
      @selected_id = selected_id
      @selected_text = selected_text
      @delay = delay
      @label = label
      @required = required
      @html_options = html_options
    end

    # nazwa inputa hidden select
    def input_name
      return @name if @name.present?
      return "#{@form.object_name}[#{@field}]" if @form && @field
      raise ArgumentError, "Either 'name' or 'form' with 'field' must be provided"
    end

    # wartość wybranej opcji
    def selected_value
      return @selected_id if @selected_id.present?
      return @form.object.public_send(@field) if @form&.object&.respond_to?(@field)
      nil
    end

    # tekst wybranej opcji
    def selected_label
      @selected_text
    end

    def has_selection?
      selected_value.present?
    end

    def container_classes
      classes = ["async-select-container"]
      classes << @html_options[:class] if @html_options[:class]
      classes.join(" ")
    end

    # ID komponentu
    def component_id
      @html_options[:id] || "async_select_#{SecureRandom.hex(4)}"
    end
  end
end
