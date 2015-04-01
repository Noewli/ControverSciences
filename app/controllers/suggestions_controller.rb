class SuggestionsController < ApplicationController

  def show
    @suggestion = Suggestion.find_by( timeline_id: params[:timeline_id] )
  end

  def index
    @suggestions = Suggestion.order( created_at: :desc).all.page(params[:page]).per(5)
    @suggestion = Suggestion.new
    if logged_in? && !@suggestion.name
      @suggestion.name = current_user.name
    elsif !@suggestion.name
      @suggestion.name = "Un illustre Anonyme"
    end
  end

  def create
    @suggestion = Suggestion.new(suggestion_params)
    if logged_in?
      @suggestion.user_id = current_user.id
    end
    if @suggestion.save
      flash[:success] = "Commentaire ajouté."
      redirect_to suggestions_path
    else
      @suggestions = Suggestion.order( :created_at).all.page(params[:page]).per(10)
      render 'index'
    end
  end

  private

  def suggestion_params
    params.require(:suggestion).permit(:comment, :name, :email)
  end
end
