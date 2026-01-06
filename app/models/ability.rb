class Ability
  include CanCan::Ability

  def initialize(user)
    # Jeśli user nie jest zalogowany, nie ma uprawnień
    return unless user

    # SUPERADMIN - dostęp do wszystkiego w systemie
    if user.superadmin?
      can :manage, :all
    
    # ADMIN organizacji - dostęp do zasobów w jego organizacji
    # acts_as_tenant automatycznie scopuje zapytania do organizacji użytkownika
    elsif user.admin?
      can :manage, User, organization_id: user.organization_id, superadmin: false
      can :manage, Client
      can :manage, ProductCategory
      can :manage, Product
      can :manage, Variant
      can :manage, Item
      can :manage, StockOperation
      can :manage, StockMovement

    # STANDARD user - ograniczony dostęp
    else
      can :read, User, organization_id: user.organization_id, superadmin: false
      can :read, Client
      can :read, ProductCategory
      can :read, Product
      can :read, Variant
      can :read, Item
      can :read, StockOperation
      can :read, StockMovement
    end
  end

end
