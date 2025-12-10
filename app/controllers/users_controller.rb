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
    if @user.update(user_params)
      redirect_to @user, notice: 'User updated successfully.'
    else
      render :edit
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
