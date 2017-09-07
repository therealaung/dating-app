class CommunitiesController < ApplicationController

  def create
    @community = Community.new(community_params)
    authorize @community
    if @community.save
      redirect_to landing_path, alert: "Your community has been submitted for approval!"
    else
      redirect_to landing_path, alert: "Something went wrong"
    end
  end

  private

  def community_params
    params.require(:community).permit(:title, :brand_color, :logo)
  end
end
