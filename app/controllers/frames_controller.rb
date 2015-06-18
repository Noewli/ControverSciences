class FramesController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :edit, :update, :destroy]

  def new
    frame = Frame.find_by( user_id: current_user.id, timeline_id: params[:timeline_id] )
    if frame
      redirect_to edit_frame_path( id: frame.id )
    else
      timeline = Timeline.find(params[:timeline_id])
      @frame = Frame.new
      @frame.content = timeline.frame
      @frame.name = timeline.name
      @frame.timeline_id = params[:timeline_id]
    end
  end

  def create
    @frame = Frame.new( timeline_id: frame_params[:timeline_id],
                            content: frame_params[:content],
                            name: frame_params[:name])
    @frame.user_id = current_user.id
    if @frame.save_with_markdown( timeline_url( frame_params[:timeline_id] ) )
      flash[:success] = "Contribution enregistrée."
      redirect_to frames_path( filter: "mine", timeline_id: @frame.timeline_id )
    else
      render 'new'
    end
  end

  def edit
    @frame = Frame.find( params[:id] )
  end

  def update
    @frame = Frame.find( params[:id] )
    @my_frame = Frame.find( params[:id] )
    if @frame.user_id == current_user.id || current_user.admin
      @frame.content = frame_params[:content]
      @frame.name = frame_params[:name]
      if @frame.save_with_markdown
        flash[:success] = "Contribution modifiée."
        redirect_to @frame
      else
        render 'edit'
      end
    else
      redirect_to @frame
    end
  end

  def show
    @frame = Frame.find(params[:id])
    if logged_in?
      @improve = Frame.where(user_id: current_user.id, timeline_id: @frame.timeline_id ).count == 1 ? false : true
    end
    @timeline = Timeline.select(:id, :nb_frames, :name ).find( @frame.timeline_id )
  end
  
  def index
    @timeline = Timeline.select(:id, :nb_frames, :name ).find( params[:timeline_id] )
    if logged_in?
      user_id = current_user.id
      @my_frame_credits = FrameCredit.where( user_id: user_id, timeline_id: params[:timeline_id] ).sum( :value )
      visit = VisiteTimeline.find_by( user_id: user_id, timeline_id: params[:timeline_id] )
      if visit
        visit.update( updated_at: Time.zone.now )
      else
        VisiteTimeline.create( user_id: user_id, timeline_id: params[:timeline_id] )
      end
      @favorites = FrameCredit.where( user_id: user_id, timeline_id: params[:timeline_id] ).count
      @improve = Frame.where(user_id: user_id, timeline_id: params[:timeline_id] ).count == 1 ? false : true
    else
      user_id = nil
    end
    if params[:filter] == "my-vote"
      frame_ids = FrameCredit.where( user_id: user_id, timeline_id: params[:timeline_id] ).pluck( :frame_id )
      @frames = Frame.where( id: frame_ids ).page(params[:page]).per(15)
    elsif params[:filter] == "mine"
      @frames = Frame.where( user_id: user_id, timeline_id: params[:timeline_id] ).page(params[:page]).per(15)
    elsif logged_in?
      if params[:seed]
        @seed = params[:seed]
      else
        @seed = rand
      end
      Frame.connection.execute("select setseed(#{@seed})")
      @frames = Frame.where(
          timeline_id: params[:timeline_id]).where.not(
          user_id: user_id).order('random()').page(params[:page]).per(15)
    else
      if !params[:sort].nil?
        if !params[:order].nil?
          @frames = Frame.order(params[:sort].to_sym => params[:order].to_sym).where(
              timeline_id: params[:timeline_id]).where.not(
              user_id: user_id).page(params[:page]).per(15)
        else
          @frames = Frame.order(params[:sort].to_sym => :desc).where(
              timeline_id: params[:timeline_id]).where.not(
              user_id: user_id).page(params[:page]).per(15)
        end
      else
        if !params[:order].nil?
          @frames = Frame.order(:score => params[:order].to_sym).where(
              timeline_id: params[:timeline_id]).where.not(
              user_id: user_id).page(params[:page]).per(15)
        else
          @frames = Frame.order(:score => :desc).page(params[:page]).where(
              timeline_id: params[:timeline_id]).where.not(
              user_id: user_id).page(params[:page]).per(15)
        end
      end
    end
  end

  def destroy
    frame = Frame.find(params[:id])
    if frame.user_id == current_user.id || current_user.admin
      frame.destroy_with_counters
      redirect_to my_items_items_path
    else
      flash[:danger] = "Cette contribution est la meilleure et ne peut être supprimée."
      redirect_to frame_path(params[:id])
    end
  end

  private

  def frame_params
    params.require(:frame).permit(:timeline_id, :content, :name )
  end
end
