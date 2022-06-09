class Webui::Users::Tokens::UsersController < Webui::WebuiController
  def index
    @token = Token::Workflow.find(params[:token_id])
    @users = @token.shared_among
    # TODO: @groups =
  end

  def create
    token = Token::Workflow.find(params[:token_id])
    user = User.find_by(login: params[:userid])

    if token.shared_among.include?(user)
      redirect_back(fallback_location: root_path, notice: "User #{user.login} is already associated to the token")
    elsif token.shared_among << user
      redirect_back(fallback_location: root_path, success: "User #{user.login} has been added to the token successfully")
    end
  end

  def destroy
    token = Token::Workflow.find(params[:token_id])
    user = User.find(params[:id])
    if token.shared_among.destroy(user)
      redirect_back(fallback_location: root_path, success: "User #{user.login} has been removed from the token successfully")
    else
      redirect_back(fallback_location: root_path, error: 'The user can not be removed from the token')
    end
  end
end
