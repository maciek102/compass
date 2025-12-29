module IndicatorsHelper

  # podstawowa etykieta statusu
  def status_label(text, klass: "", style: "")
    content_tag(:span, text, class: "status-indicator #{klass}", style: style)
  end

  # podstawowa etykieta kierunku operacji magazynowej
  def direction_label(direction)
    case direction.to_s
    when "receive", "in"
      content_tag(:span, class: "direction-indicator in") do
        tag.i(class: "fa fa-arrow-circle-down me-1") + I18n.t("directions.in")
      end
    when "issue", "out"
      content_tag(:span, class: "direction-indicator out") do
        tag.i(class: "fa fa-arrow-circle-up me-1") + I18n.t("directions.out")
      end
    else
      content_tag(:span, class: "direction-indicator") do
        tag.i(class: "fa fa-question-circle me-1") + I18n.t("directions.unknown")
      end
    end
  end

end