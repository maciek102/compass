module Tables
  # === ViewModeSwitcherComponent ===
  # Komponent do przełączania widoków (scope) tabeli.
  # Użycie:
  #   = render Tables::ViewModeSwitcherComponent.new(view_modes: @view_modes, base_params: params)
     
  class ViewModeSwitcherComponent < ViewComponent::Base
    def initialize(view_modes:, base_params:)
      @view_modes = view_modes
      @base_params = base_params
    end

    def url_for_mode(mode)
      url_for(@base_params.permit!.merge(view: mode))
    end
  end
end