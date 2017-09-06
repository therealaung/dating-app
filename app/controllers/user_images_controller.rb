class UserImagesController < ApplicationController
  def new
    @user = User.find(params[:profile_id])
    authorize @user, :new_image?
  end

  def create
  end

  def show
    @user = User.find(params[:profile_id])
    @photo = @user.user_images.find(params[:id])
    authorize @photo
  end

  def update

  end

  def destroy
    @photo = UserImage.find(params[:id])
    authorize @photo
    if @photo.delete
      redirect_to edit_profile_path(current_user)
    else
      render :show
    end
  end

end
