class StaticPagesController < ApplicationController
  def home
    @timelines = Timeline.order(:score => :desc).first(8)
    if logged_in?
      @my_likes = Like.where(user_id: current_user.id).pluck( :timeline_id )
    end
  end

  def empty_comments
    if params[:filter] == "mine" && logged_in?
      @references = Reference.select(:id, :title, :timeline_id, :created_at).order(:created_at => :desc).where( title_fr: nil, user_id: current_user.id )
    else
      @references = Reference.select(:id, :title, :timeline_id, :created_at).order(:created_at => :desc).where( title_fr: nil )
    end
  end

  def empty_summaries
    @timelines = Timeline.select(:id, :name, :created_at).order(:created_at => :desc).where( nb_summaries: 0 ).where.not( nb_references: 0..3 )
  end

  def empty_references
    @timelines = Timeline.select(:id, :name, :created_at).order(:created_at => :desc).where( nb_references: 0..3 )
  end

  def newsletter
  end
end
