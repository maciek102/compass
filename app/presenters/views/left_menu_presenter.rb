module Views
  # generator lewego menu na podstawie roli usera i opcjonalnego kontekstu
  # menu główne - podstawowe menu zależne od roli usera
  # menu kontekstowe - dodatkowe menu zależne od kontekstu (np. produkty - lista produktów + kategorie)
  # dostępne konteksty - :products, :warehouse
  # menu superadmina - działa na podstawie flagi w User
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
      # superadmin ma możliwość przełączania się na widok "zwykłego" usera, zależne od flagi superadmin_view w User
      return admin_menu unless user.superadmin_view 

      # domyślne menu superadmina
      [
        { text: "Dashboard", url: Rails.application.routes.url_helpers.dashboard_user_path(user), icon: dashboard_icon },
        { text: "Organizacje", url: Rails.application.routes.url_helpers.organizations_path, icon: Organization.icon },
        { text: "Użytkownicy", url: Rails.application.routes.url_helpers.users_path, icon: User.icon }
      ]
    end

    def admin_menu
      [
        { text: "Dashboard", url: Rails.application.routes.url_helpers.dashboard_user_path(user), icon: dashboard_icon },
        { text: "Magazyn", url: warehouse_context.first[:url], icon: StockOperation.icon },
        { text: "Produkty", url: products_context.first[:url], icon: Product.icon },
        { text: "Oferty", url: Rails.application.routes.url_helpers.offers_path, icon: Offer.icon },
        { text: "Klienci", url: Rails.application.routes.url_helpers.clients_path, icon: Client.icon },
        { text: "Użytkownicy", url: Rails.application.routes.url_helpers.users_path, icon: User.icon },
        { text: "Skaner", url: Rails.application.routes.url_helpers.scanner_variants_path, icon: "barcode" },
        { text: "Ustawienia", url: Rails.application.routes.url_helpers.dashboard_organizations_path, icon: "cog" }
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

    # menu produktowe
    def products_context
      [
        { text: "Produkty", url: Rails.application.routes.url_helpers.products_path, icon: Product.icon },
        { text: "Warianty", url: Rails.application.routes.url_helpers.variants_path, icon: Variant.icon },
        { text: "Kategorie", url: Rails.application.routes.url_helpers.product_categories_path, icon: ProductCategory.icon }
      ]
    end

    # menu magazynowe
    def warehouse_context
      [
        { text: "Stan", url: Rails.application.routes.url_helpers.stock_index_variants_path, icon: Variant.icon },
        { text: "Operacje", url: Rails.application.routes.url_helpers.stock_operations_path, icon: StockOperation.icon },
        { text: "Ruchy magazynowe", url: Rails.application.routes.url_helpers.stock_movements_path, icon: StockMovement.icon }
      ]
    end
    
  end
end