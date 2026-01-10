# bazowy concern dla modeli należących do tenantów (organizacji)
module Tenantable
  extend ActiveSupport::Concern

  included do
    acts_as_tenant(:organization)
  end
end