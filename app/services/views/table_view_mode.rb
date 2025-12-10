module Views

  # service do przełączania różnych trybów widoku tabeli (np. kategorie - wszystkie / tylko roots)
  class TableViewMode
    attr_reader :current, :default, :modes

    def initialize(current_param, default:, modes:)
      @default = default.to_sym
      @modes = modes.transform_keys(&:to_sym)
      @current = current_param&.to_sym
      @current = @default unless @modes.key?(@current)
    end

    def current?(mode)
      current == mode
    end

    def available_modes
      @modes.keys
    end

    def label_for(mode)
      @modes[mode][:label]
    end

    def apply(scope)
      @modes[current][:scope].call(scope)
    end
  end

end