class UserDetailsController < ApplicationController
  before_action :logged_in_user, only: [:create]

  def create
    @user_details = UserDetail.find_by_user_id( user_detail_params[:user_id] )
    if @user_details
      @user_details.update(user_detail_params)
      if user_detail_params[:delete_picture] == 'true'
        @user_details.remove_picture!
      end
    else
      @user_details = UserDetail.new(user_detail_params)
    end
    if @user_details.save
      flash[:info] = "Modification de profil enregistrée."
      redirect_to user_path(id: user_detail_params[:user_id] )
    else
      redirect_to user_edit_path(id: user_detail_params[:user_id] )
    end
  end

  private

  def user_detail_params
    params.require(:user_detail).permit(:user_id, :job, :institution, :website, :biography, :picture, :delete_picture)
  end
end
