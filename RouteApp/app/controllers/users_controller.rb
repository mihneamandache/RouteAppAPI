class UsersController < ApplicationController

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user
    else
      render json: "Error"
    end
  end

  def user_params
    params.require(:user).permit(
      :name,
      :last_name,
      :unique_identifier
    )
  end
end
