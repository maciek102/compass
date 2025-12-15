class UsersController < ApplicationController
  load_and_authorize_resource

  def dashboard
    
  end

  def index
    @search_url = users_path

    @search = User.all.ransack(params[:q])
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

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :role_mask)
  end
end
