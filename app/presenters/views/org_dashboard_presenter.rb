module Views
  # generator menu ustawień organizacji dla adminów organizacji

  class OrgDashboardPresenter
    include IconsHelper
    
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def build
      return [] unless user

      role_menu(user)
    end

    private

    def role_menu(user)
      role = user.role_name

      case role.to_sym
      when :superadmin then admin_menu
      when :admin then admin_menu
      when :user then user_menu
      else []
      end
    end

    def admin_menu
      [
        { text: "Profil organizacji", url: routes.organization_profile_path(user.organization.organization_profile), icon: Organization.icon },
        { text: "Importy", url: routes.import_runs_path, icon: ImportRun.icon }
      ]
    end

    def user_menu
      [
        
      ]
    end

    def routes
      Rails.application.routes.url_helpers
    end
    
  end
end