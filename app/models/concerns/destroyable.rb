module Destroyable
  extend ActiveSupport::Concern

  included do
    scope :active, ->{where(disabled: false)}
    scope :not_active, ->{where(disabled: true)}
    def active?
      !disabled?
    end

    def disable_me
      update!(disabled: true)
    end

    def enable_me
      update!(disabled: false)
    end

    def destroy
      disable_me
    end

    def self.active_with_param(show_disabled=false)
      show_disabled.to_s == 'true' ? not_active : active
    end
  end



  # module ClassMethods
  #
  # end
end
