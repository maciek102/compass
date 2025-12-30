class UsersController < ApplicationController
  load_and_authorize_resource

  def dashboard
    
  end

  def index
    @search_url = users_path

    @search = User.for_user(current_user).ransack(params[:q])
    @list = @users = @search.result(distinct: true).page(params[:page])

    respond_to do |f|
      f.html
      f.js {render "application/index"}
    end
  end

  def show
  end

  def edit
  end

  def new
    
  end

  def create
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save
        flash[:notice] = flash_message(User, :create)

        format.turbo_stream
        format.html { redirect_to users_path, notice: flash[:notice] }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @user.update(user_params)
        @list = @users = User.all.page(params[:page])

        flash[:notice] = flash_message(User, :update)

        format.turbo_stream
        format.html { redirect_to users_path, notice: flash[:notice] }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  
  def superadmin_menu
    return unless current_user.superadmin?

    current_user.update!(organization_id: params[:user][:organization_id], superadmin_view: params[:user][:superadmin_view])

    redirect_to request.referer, notice: t('superadmin.organization_switch.success')
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role_mask, :organization_id, :is_superadmin)
  end
end
