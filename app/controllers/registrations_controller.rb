class RegistrationsController < Devise::RegistrationsController

  def sign_up_params
    params.require(:user).permit(:name, :last_name, :first_name, :email, :password, :password_confirmation,
      :stripe_token)
  end
end
