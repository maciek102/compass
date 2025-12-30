class OrganizationsController < ApplicationController
  load_and_authorize_resource

  def index
    @search_url = organizations_path

    @search = @organizations.ransack(params[:q])
    @list = @organizations = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
    @tab = params[:tab] || "main"

    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    
  end

  def create
    @organization = Organization.new(organization_params)

    respond_to do |format|
      if @organization.save

        flash[:notice] = flash_message(Organization, :create)

        format.turbo_stream
        format.html { redirect_to @organization, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @organization.update(organization_params)

        flash[:notice] = flash_message(Organization, :update)

        format.turbo_stream
        format.html { redirect_to organizations_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  private

  def organization_params
    params.require(:organization).permit(:name, :description, :launched, :disabled)
  end
end
