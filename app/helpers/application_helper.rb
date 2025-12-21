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

  # link do widoku show zasobu
  # extra params np: extra_params: { from: "orders", view: params[:view] }
  def resource_show_link(resource, text = nil, extra_params: {})
    link_to fa_icon("arrow-right", text: text), polymorphic_path(resource, extra_params), class: "action-button", title: "Pokaż", data: { turbo: "false" }
  end

  # link do edycji zasobu np. w tabelach
  # extra params np: extra_params: { from: "orders", view: params[:view] }
  def resource_edit_link(resource, text = nil, extra_params: {})
    link_to fa_icon("edit", text: text), edit_polymorphic_path(resource, extra_params), class: "action-button yellow", title: "Edytuj #{resource.class.model_name.human.downcase}", data: { turbo: "false" }
  end

  # link do edycji zasobu np. w tabelach, używający turbo
  # extra params np: extra_params: { from: "orders", view: params[:view] }
  def resource_turbo_edit_link(resource, text = nil, extra_params: {})
    link_to edit_polymorphic_path(resource, extra_params), class: "action-button yellow", title: "Edytuj #{resource.class.model_name.human.downcase}", data: { turbo_frame: "modal" } do
      fa_icon("edit", text: text)
    end
  end

  # link do usunięcia / dezaktywacji zasobu np. w tabelach
  def resource_destroy_link(resource, text = nil)
    if can?(:destroy, resource)
      if resource.try(:active?)
        link_to fa_icon("trash", text: text), resource, method: :delete, data: { confirm: "Jesteś tego pewien?", turbo: false }, class: "action-button red", title: t(:destroy), remote: true
      elsif resource.respond_to? :active?
        link_to fa_icon("check"), url_for([resource,enable_me: true]), method: :delete, data: { confirm: "Jesteś pewien, że chcesz przywrócić?", turbo: false }, class: "action-button", title: t(:renew)
      else
        link_to fa_icon("trash", text: text), resource, method: :delete, data: { confirm: "Jesteś tego pewien?", turbo: false }, class: "action-button red", title: t(:destroy)
      end
    end
  end

  # switch do przełączania trybów widoku tabeli (TableViewMode)
  def view_mode_switcher(view_modes, base_path)
    content_tag :div, class: "view-switcher" do
      view_modes.available_modes.map do |mode|
        link_to base_path.call(view: mode), class: "view-switcher-button #{'active' if view_modes.current?(mode)}" do
          view_modes.label_for(mode)
        end
      end.join.html_safe
    end
  end

  def show_datetime(date)
    date.present? ? date.strftime("%d.%m.%Y %H:%M") : "-"
  end

  def show_date(date)
    date.present? ? date.strftime("%d.%m.%Y") : "-"
  end

end
