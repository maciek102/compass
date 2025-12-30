class Ability
  include CanCan::Ability

  def initialize(user)
    # Jeśli user nie jest zalogowany, nie ma uprawnień
    return unless user

    # SUPERADMIN - dostęp do wszystkiego w systemie
    if user.superadmin?
      can :manage, :all
    
    # ADMIN organizacji - dostęp do zasobów w jego organizacji
    elsif user.admin?
      can :manage, User, organization_id: user.organization_id, superadmin: false
      can :manage, ProductCategory, organization_id: user.organization_id
      can :manage, Product, organization_id: user.organization_id
      can :manage, Variant, organization_id: user.organization_id
      can :manage, Item, organization_id: user.organization_id
      can :manage, StockOperation, organization_id: user.organization_id
      can :manage, StockMovement, organization_id: user.organization_id

    # STANDARD user - ograniczony dostęp
    else
      can :read, User, organization_id: user.organization_id, superadmin: false
      can :read, ProductCategory, organization_id: user.organization_id
      can :read, Product, organization_id: user.organization_id
      can :read, Variant, organization_id: user.organization_id
      can :read, Item, organization_id: user.organization_id
      can :read, StockOperation, organization_id: user.organization_id
      can :read, StockMovement, organization_id: user.organization_id
    end
  end

end
