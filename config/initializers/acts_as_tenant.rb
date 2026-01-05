# Konfiguracja acts_as_tenant gem
# Dokumentacja: https://github.com/ErwinM/acts_as_tenant

ActsAsTenant.configure do |config|
  # Wymagaj ustawienia tenanta dla wszystkich zapytań (bezpieczeństwo)
  # Możesz to zmienić na false jeśli chcesz więcej elastyczności
  config.require_tenant = true
  
  # Domyślnie gem rzuca wyjątek jeśli tenant nie jest ustawiony
  # Ustaw false aby po prostu zwrócić pusty wynik
  # config.pkey = :id
end
