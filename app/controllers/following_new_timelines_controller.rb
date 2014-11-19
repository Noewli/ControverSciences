class FollowingNewTimelinesController < ApplicationController

  before_action :logged_in_user, only: [:create, :destroy]

  def create
    if params[:tag]
      tag = Tag.find_by_name(params[:tag])
      follow = FollowingNewTimeline.new( user_id: current_user.id, tag_id: tag.id)
      if follow.save
        flash[:success] = "Petit curieux, vous suivez maintenant toutes les nouvelles controverses contenant le tag #{tags_hash[params[:tag]]}"
      else
        flash[:danger] = "Vous êtiez déjà attentif aux nouvelles controverses contenant le tag #{tags_hash[params[:tag]]}"
      end
    else
      tag_ids = Tag.all.pluck(:id)
      tag_ids.each do |tag_id|
        follow = FollowingNewTimeline.new( user_id: current_user.id, tag_id: tag_id)
        follow.save
      end
      flash[:success] = "Grand curieux, vous suivez maintenant toutes les nouvelles controverses"
    end
    redirect_to timelines_path
  end

  def destroy
    fo = FollowingNewTimeline.find_by( user_id: current_user.id, tag_id: params[:id] )
    unless fo.nil?
      fo.destroy
    end
    redirect_to followings_index_path
  end
end
