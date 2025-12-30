module Forms
  # === TileSelectComponent ===
  # Komponent do wyboru opcji w formie kafelków.
  # Użycie:
  #   = render Forms::TileSelectComponent.new(form: f, field: :field_name, label: "Etykieta", options: { key: "Label", ... })
  #   lub
  #   = render Forms::TileSelectComponent.new(form: f, field: :field_name, label: "Etykieta", options: [["Label", key], ...])
  class TileSelectComponent < ViewComponent::Base
    def initialize(form: nil, field:, options:, value: nil, name: nil, label: nil, style: "", input_data: {})
      @form = form
      @field = field
      @options = normalize_options(options)
      @value = value
      @input_name = name || field
      @input_data = input_data || {}

      @label = label
      @style = style
    end

    def selected
      return @form.object.public_send(@field) if @form&.object&.respond_to?(@field)

      @value
    end

    private

    def normalize_options(options)
      # Ensure options are in {key => label} format
      if options.is_a?(Hash)
        options
      elsif options.is_a?(Array)
        # If array, convert [label, key] pairs to {key => label}
        options.each_with_object({}) { |(label, key), hash| hash[key] = label }
      else
        options
      end
    end

    def input_data
      { tile_select_target: "select" }.merge(@input_data)
    end
  end
end
