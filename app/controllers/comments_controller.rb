class CommentsController < ApplicationController
  before_action :logged_in_user, only: [:new, :create, :edit, :update, :destroy]

  def new
    comment = Comment.find_by( user_id: current_user.id, reference_id: params[:reference_id] )
    if comment
      redirect_to edit_comment_path( id: comment.id, parent_id: params[:parent_id] )
    else
      @comment = Comment.new
      if params[:parent_id]
        @parent = Comment.find(params[:parent_id])
        for fi in 0..5 do
          @comment["f_#{fi}_content".to_sym] = @parent["f_#{fi}_content".to_sym]
          @comment.title = @parent.title
          @comment.reference_id = @parent.reference_id
          @comment.timeline_id = @parent.timeline_id
        end
      else
        reference = Reference.select(:id, :timeline_id).find( params[:reference_id] )
        @comment.reference_id = reference.id
        @comment.timeline_id = reference.timeline_id
      end
      @list = Reference.where( timeline_id: @comment.timeline_id ).pluck( :title, :id )
    end
  end

  def create
    @comment = Comment.new( comment_params )
    if comment_params[:picture] && comment_params[:delete_picture] == 'false'
      @comment.picture = comment_params[:picture]
      @comment.caption = comment_params[:caption]
    else
      @comment.caption = ''
      @comment.remove_picture!
    end
    @comment.user_id = current_user.id
    parent_id = params[:comment][:parent_id]
    if @comment.save_with_markdown( timeline_url( comment_params[:timeline_id] ) )
      if parent_id
        CommentRelationship.create(parent_id: parent_id, child_id: @comment.id)
      end
      flash[:success] = "Analyse enregistrée."
      redirect_to comment_path( @comment.id )
    else
      @list = Reference.where( timeline_id: comment_params[:timeline_id] ).pluck( :title, :id )
      if parent_id
        @parent = Comment.find( parent_id )
      end
      render 'new'
    end
  end

  def edit
    @my_comment = Comment.find( params[:id] )
    @comment = @my_comment
    @list = Reference.where( timeline_id: @comment.timeline_id ).pluck( :title, :id )
    if params[:parent_id]
      @parent = Comment.find(params[:parent_id])
      if @parent.user_id != current_user.id
        for fi in 0..5 do
          @comment["f_#{fi}_content".to_sym] += "\n" + @parent["f_#{fi}_content".to_sym]
          @comment.title += "\n" + @parent.title
        end
      else
        @parent = nil
      end
    end
  end

  def update
    @comment = Comment.find( params[:id] )
    @my_comment = Comment.find( params[:id] )
    if @comment.user_id == current_user.id
      @comment.public = comment_params[:public]
      for fi in 0..5 do
        @comment["f_#{fi}_content".to_sym] = comment_params["f_#{fi}_content".to_sym]
      end
      @comment.title = comment_params[:title]
      if comment_params[:delete_picture] == 'true'
        @comment.caption = ''
        @comment.remove_picture!
      elsif comment_params[:picture]
        @comment.picture = comment_params[:picture]
        @comment.caption = comment_params[:caption]
      end
      if @comment.update_with_markdown( timeline_url( @comment.timeline_id ) )
        flash[:success] = "Analyse modifiée."
        redirect_to @comment
      else
        @list = Reference.where( timeline_id: @comment.timeline_id ).pluck( :title, :id )
        if params[:comment][:parent_id]
          @parent = Comment.find(params[:comment][:parent_id])
        end
        render 'edit'
      end
    else
      redirect_to @comment
    end
  end

  def show
    @comment = Comment.select( :id, :user_id, :reference_id, :timeline_id, :markdown_0,
                               :markdown_1, :markdown_2, :markdown_3, :markdown_4,
                               :markdown_5, :balance, :best, :public,
                               :created_at, :picture, :caption_markdown, :title_markdown
                              ).find(params[:id])
    unless @comment.public
      if current_user && current_user.id == @comment.user_id
        flash.now[:info] = "Cette analyse est privée."
      else
        flash[:danger] = "Vous n'avez pas l'autorisation d'accéder à cette page, le contenu à été rendu privé par son auteur."
        redirect_to reference_path(@comment.reference_id)
      end
    end
  end

  def destroy
    comment = Comment.find(params[:id])
    if comment.user_id == current_user.id && !comment.best
      comment.destroy_with_counters
      redirect_to my_items_items_path
    else
      flash[:danger] = "Cette analyse est la meilleure pour cette référence et ne peut être supprimée."
      redirect_to comment_path(params[:id])
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:id, :reference_id, :timeline_id, :f_0_content, :f_1_content, :f_2_content,
                                    :f_3_content, :f_4_content, :f_5_content, :public, :picture, :caption, :delete_picture, :title)
  end
end
