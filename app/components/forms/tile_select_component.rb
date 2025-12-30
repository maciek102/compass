module Forms
  # === TileSelectComponent ===
  # Komponent do wyboru opcji w formie kafelków.
  # Użycie:
  #   = render Forms::TileSelectComponent.new(form: f, field: :field_name, label: "Etykieta", options: { key: "Label", ... })
  #   lub
  #   = render Forms::TileSelectComponent.new(form: f, field: :field_name, label: "Etykieta", options: [["Label", key], ...])
  class TileSelectComponent < ViewComponent::Base
    def initialize(form:, field:, label:, options:)
      @form = form
      @field = field
      @label = label
      @options = normalize_options(options)
    end

    def selected
      @form.object.public_send(@field)
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
  end
end
