class OrganizationProfilesController < ApplicationController
  load_and_authorize_resource

  def show
    
  end

  def edit
  end

  def update
    if @organization_profile.update(organization_profile_params)
      respond_to do |f|
        f.html { redirect_to organization_profile_path, notice: 'Profil organizacji został zaktualizowany.' }
        f.js { render 'application/update' }
      end
    else
      respond_to do |f|
        f.html { render :edit }
        f.js { render 'application/edit_error' }
      end
    end
  end

  private

  def organization_profile_params
    params.require(:organization_profile).permit(
      :company_name,
      :tax_id,
      :registration_number,
      :address_street,
      :address_building,
      :address_apartment,
      :address_city,
      :address_postcode,
      :address_country,
      :contact_email,
      :contact_phone,
      :inpost_organization_id,
      :inpost_api_key
    )
  end
end
