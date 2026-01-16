module SimpleForm
  module Components
    module Icon
      def icon(wrapper_options = nil)
        return unless options[:icon]
        
        icon_name = options[:icon]
        icon_class = options[:icon_class] || 'input-icon'
        
        template.content_tag(:span, '', 
          class: ['iconify', icon_class].compact.join(' '),
          data: { icon: icon_name }
        )
      end
    end
  end
end

SimpleForm::Inputs::Base.include SimpleForm::Components::Icon