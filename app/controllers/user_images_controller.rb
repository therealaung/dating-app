class UserImagesController < ApplicationController

  def show
    @user = User.find(params[:profile_id])
    @photo = @user.user_images.find(params[:id])

  end

  def update

  end

  def destroy
    @photo = UserImage.find(params[:id])
    if @photo.delete
      redirect_to edit_profile_path(current_user)
    else
      render :show
    end
  end

end