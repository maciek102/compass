module Views
  # generator lewego menu na podstawie roli usera i opcjonalnego kontekstu
  # menu główne - podstawowe menu zależne od roli usera
  # menu kontekstowe - dodatkowe menu zależne od kontekstu (np. produkty - lista produktów + kategorie)
  # dostępne konteksty - :products, :warehouse
  class LeftMenuPresenter
    include IconsHelper
    
    attr_reader :user, :context # automatyczny getter

    def initialize(user:, context: nil)
      @user = user
      @context = context
    end

    def build
      return [] unless user

      if context.present?
        return contextual_menu(context)
      end

      role_menu(user)
    end

    private

    # === MENU GŁÓWNE ===

    # główne menu na podstawie roli usera
    def role_menu(user)
      role = user.role_name

      case role.to_sym
      when :superadmin then superadmin_menu
      when :admin then admin_menu
      when :user then user_menu
      else []
      end
    end

    def superadmin_menu
      superadmin_menu = [
        { text: "Dashboard", url: Rails.application.routes.url_helpers.dashboard_user_path(user), icon: dashboard_icon },
        { text: "Organizacje", url: Rails.application.routes.url_helpers.organizations_path, icon: Organization.icon },
        { text: "Użytkownicy", url: Rails.application.routes.url_helpers.users_path, icon: User.icon }
      ]

      user.superadmin_view ? superadmin_menu : admin_menu
    end

    def admin_menu
      [
        { text: "Dashboard", url: Rails.application.routes.url_helpers.dashboard_user_path(user), icon: dashboard_icon },
        { text: "Magazyn", url: Rails.application.routes.url_helpers.stock_operations_path, icon: StockOperation.icon },
        { text: "Produkty", url: Rails.application.routes.url_helpers.products_path, icon: Product.icon },
        { text: "Użytkownicy", url: Rails.application.routes.url_helpers.users_path, icon: User.icon }
      ]
    end

    def user_menu
      [
        { text: "Moje konto", url: Rails.application.routes.url_helpers.edit_user_path(user), icon: User.icon }
      ]
    end

    # === MENU KONTEKSTOWE ===

    # menu kontekstowe (np. produkty)
    def contextual_menu(ctx)
      # back_link = { text: "Wyjdź", url: role_menu(user).first[:url], icon: "arrow-left" }
      back_link = { text: "Wyjdź", url: Rails.application.routes.url_helpers.dashboard_user_path(user), icon: "arrow-left" }

      [back_link] + contextual_menu_links(ctx)
    end

    def contextual_menu_links(ctx)
      case ctx.to_sym
      when :products then products_context
      when :warehouse then warehouse_context
      else []
      end
    end

    def products_context
      [
        { text: "Produkty", url: Rails.application.routes.url_helpers.products_path, icon: Product.icon },
        { text: "Warianty", url: Rails.application.routes.url_helpers.variants_path, icon: Variant.icon },
        { text: "Kategorie", url: Rails.application.routes.url_helpers.product_categories_path, icon: ProductCategory.icon }
      ]
    end

    def warehouse_context
      [
        { text: "Operacje", url: Rails.application.routes.url_helpers.stock_operations_path, icon: StockOperation.icon },
        { text: "Ruchy magazynowe", url: Rails.application.routes.url_helpers.stock_movements_path, icon: StockMovement.icon }
      ]
    end
    
  end
end