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

  # generuje link do dodania zagnieżdżonych pól formularza (nested fields)
  def link_to_add_fields(name, f, association, klass = "", options={})
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    partial_name = association.to_s.singularize + "_fields"
    partial_name = options[:partial_name] if options[:partial_name]
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(partial_name, f: builder, options: options)
    end
    link_to(name, '#', class: "add_fields #{klass}", data: {id: id, fields: fields.gsub("\n", ""), controller: "nested", action: "nested#addNewRow"}, title: name)
  end

  def not_standard_url(url)
    url ? {url: url} : {}
  end

  # funkcja tworząca wiersz do widoków show do kontenera .info
  def category_info_row(label, value)
    content_tag(:div, class: "info-row") do
      concat(content_tag(:div, "#{label}:", class: "info-label"))
      concat(content_tag(:div, value, class: "info-value"))
    end
  end

  def yes_no(boolean)
    boolean ? "Tak" : "Nie"
  end
end
