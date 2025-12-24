module ItemPicker
  # Klasa odpowiedzialna za rozwiązywanie strategii wyboru itemów na podstawie podanego symbolu
  class Resolver

    def self.call(strategy:, scope:, **options)

      case strategy.to_sym
      when :fifo
        FIFO.new(scope: scope)
      when :fefo
        FEFO.new(scope: scope)
      when :manual
        Manual.new(scope: scope, item_ids: options.fetch(:item_ids))
      else
        raise ArgumentError, "Unknown picker strategy: #{strategy}"
      end
      
    end

  end
end
