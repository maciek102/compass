module Views
  # generator lewego menu na podstawie roli usera i opcjonalnego kontekstu
  # menu główne - podstawowe menu zależne od roli usera
  # menu kontekstowe - dodatkowe submenu pod głównym elementem (np. produkty -> warianty, kategorie)
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

      menu = role_menu(user)
      
      # Rozwiń submenu dla aktywnego kontekstu
      if context.present?
        expand_context_in_menu(menu, context)
      else
        menu
      end
    end

    private

    # submenu dla aktywnego kontekstu
    def expand_context_in_menu(menu, ctx)
      menu.map do |item|
        if item[:context] == ctx
          item.merge(children: contextual_menu_links(ctx), expanded: true)
        else
          item
        end
      end
    end

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
        { text: "Dashboard", url: routes.dashboard_user_path(user), icon: dashboard_icon },
        { text: "Organizacje", url: routes.organizations_path, icon: Organization.icon },
        { text: "Użytkownicy", url: routes.users_path, icon: User.icon }
      ]
    end

    def admin_menu
      [
        { text: "Dashboard", url: routes.dashboard_user_path(user), icon: dashboard_icon },
        { text: "Magazyn", url: warehouse_context.first[:url], icon: StockOperation.icon, context: :warehouse },
        { text: "Produkty", url: products_context.first[:url], icon: Product.icon, context: :products },
        { text: "Oferty", url: routes.offers_path, icon: Offer.icon },
        { text: "Zamówienia", url: routes.orders_path, icon: Order.icon },
        { text: "Klienci", url: routes.clients_path, icon: Client.icon },
        { text: "Użytkownicy", url: routes.users_path, icon: User.icon },
        { text: "Skaner", url: routes.scanner_variants_path, icon: "barcode" },
        { text: "Ustawienia", url: routes.dashboard_organizations_path, icon: "cog" }
      ]
    end

    def user_menu
      [
        { text: "Moje konto", url: routes.edit_user_path(user), icon: User.icon }
      ]
    end

    # === SUBMENU KONTEKSTOWE ===

    # Zwraca linki submenu dla danego kontekstu
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
        { text: "Produkty", url: routes.products_path, icon: Product.icon },
        { text: "Warianty", url: routes.variants_path, icon: Variant.icon },
        { text: "Kategorie", url: routes.product_categories_path, icon: ProductCategory.icon }
      ]
    end

    # menu magazynowe
    def warehouse_context
      [
        { text: "Stan", url: routes.stock_index_variants_path, icon: Variant.icon },
        { text: "Operacje", url: routes.stock_operations_path, icon: StockOperation.icon },
        { text: "Ruchy magazynowe", url: routes.stock_movements_path, icon: StockMovement.icon }
      ]
    end

    def routes
      Rails.application.routes.url_helpers
    end
    
  end
end