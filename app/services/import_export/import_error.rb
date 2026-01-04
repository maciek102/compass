module ImportExport
  # Błąd importu z informacją o linii, w której wystąpił
  # Ułatwia identyfikację i debugowanie problemów podczas procesu importu danych.
  # Przyjmuje numer linii oraz wiadomość błędu jako argumenty konstruktora.
  # Dziedziczy po StandardError, aby zachować standardowe zachowanie wyjątków w Ruby.

  class ImportError < StandardError
    attr_reader :line

    def initialize(line, message)
      @line = line
      super("Linia #{line}: #{message}")
    end
  end
end
