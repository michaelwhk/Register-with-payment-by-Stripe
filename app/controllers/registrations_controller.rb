class RegistrationsController < Devise::RegistrationsController
  before_action :cancel_subscription, only: [:destroy]

  private
  def sign_up_params
    params.require(:user).permit(:name, :last_name, :first_name, :email, :password, :password_confirmation,
      :stripe_token)
  end

  def cancel_subscription
    subscription = Stripe::Subscription.retrieve(current_user.subscription_id)
    subscription.delete
  end
end
