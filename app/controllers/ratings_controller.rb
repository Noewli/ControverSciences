class RatingsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]

  def create
    if params[:update]
      @rating = Rating.where({user_id: current_user.id,reference_id: rating_params[:reference_id]}).first
      if @rating.update( {value: rating_params[:value]})
        flash[:success] = "Changement enregistré"
        redirect_to controller: 'references', action: 'show', id: rating_params[:reference_id]
      else
        render 'static_pages/home'
      end
    else
      @rating = Rating.new({user_id: current_user.id,
                            timeline_id: rating_params[:timeline_id],
                            reference_id: rating_params[:reference_id], value: rating_params[:value]})
      if @rating.save
        case rating_params[:value]
          when 1 || 2
            flash[:info] = "ZZbrraa, comment vous l'avez défoncé la référence !"
          when 3
            flash[:info] = "Ca va, vous vous mouillez pas trop !"
          else
            flash[:info] = "Mais quelle éloge de cette référence !"
        end
        redirect_to reference_url( rating_params[:reference_id] )
      else
        redirect_to root_url
      end
    end
  end

  def destroy
  end

  private

  def rating_params
    params.require(:rating).permit(:reference_id, :timeline_id, :value)
  end
end
