module LogsHelper

  def format_log_detail(detail)
    if detail.is_a?(Array) && detail.size == 2
      old_value, new_value = detail
      return content_tag(:span, new_value.to_s) unless old_value.present?

      content_tag(:span, "#{old_value} → #{new_value}")
    else
      content_tag(:span, detail.to_s)
    end
  end

end