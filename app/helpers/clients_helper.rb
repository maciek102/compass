module ClientsHelper
  # Zwraca status klienta z odpowiednim kolorem
  def client_status_badge(client)
    if client.disabled?
      content_tag(:span, "Wyłączony", class: "badge badge--danger")
    else
      content_tag(:span, "Aktywny", class: "badge badge--success")
    end
  end

  # Zwraca skrót adresu
  def client_address_short(client)
    client.address ? client.address.truncate(50) : "—"
  end

  # Zwraca pełny adres
  def client_full_address(client)
    client.full_address
  end

  # Zwraca link do edycji klienta
  def edit_client_link(client, label = "Edytuj")
    link_to label, edit_client_path(client), class: "action-link"
  end

  # Zwraca link do usunięcia klienta
  def delete_client_link(client, label = "Usuń")
    link_to label, client_path(client), method: :delete, data: { confirm: "Na pewno chcesz usunąć tego klienta?" }, class: "action-link action-link--danger"
  end

  # Zwraca krótki opis klienta dla notyfikacji
  def client_notification_text(client, action = "created")
    case action
    when "created"
      "Klient #{client.name} został dodany"
    when "updated"
      "Klient #{client.name} został zaktualizowany"
    when "deleted"
      "Klient #{client.name} został usunięty"
    else
      client.name
    end
  end
end
