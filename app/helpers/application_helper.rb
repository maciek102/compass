module ApplicationHelper

  # url: gdzie link prowadzi; text: tekst linku; icon: nazwa ikony FA, np. "users"; active: true/false, klass: dodatkowa klasa opcjonalna, turbo_enabled: true/false (czy włączać turbo)
  def left_menu_link(url:, text:, icon:, active: false, klass: nil, turbo_enabled: true)
    link_classes = ["left-menu-link"]
    link_classes << "active" if active
    link_classes << klass if klass.present?

    link_to url, class: link_classes.join(" "), title: text, data: (turbo_enabled ? {} : { turbo: false }) do
      fa_icon(icon, text: text)
    end
  end

end
