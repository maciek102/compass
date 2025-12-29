module ItemPicker
  # Klasa odpowiedzialna za rozwiązywanie strategii wyboru itemów na podstawie podanego symbolu
  class Resolver

    def self.call(strategy:, scope:, **options)

      case strategy.to_sym
      when :fifo
        ItemPicker::Fifo.new(scope: scope)
      when :fefo
        ItemPicker::Fefo.new(scope: scope)
      when :manual
        ItemPicker::Manual.new(scope: scope, item_ids: options.fetch(:item_ids))
      else
        raise ArgumentError, "Unknown picker strategy: #{strategy}"
      end
      
    end

  end
end
