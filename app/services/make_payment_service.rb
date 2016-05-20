class MakePaymentService

  def perform(user)
    if !user.stripe_token.present?
      user.errors[:base] << 'Could not verify card.'
      raise ActiveRecord::RecordInvalid.new(user)
    end
    customer = create_customer(user)
    subscription = create_subscribe(customer)
    user.subscription_id = subscription.id

    # Charge works for one time payment
    # charge = create_charge(customer)

    user.stripe_token = nil
    Rails.logger.info("Stripe subscription for #{user.email}") if subscription[:status] == 'active'

    # Print logger for charge if charge done
    # Rails.logger.info("Stripe transaction for #{user.email}") if charge[:paid] == true

  rescue Stripe::InvalidRequestError => e
    user.errors[:base] << e.message
    user.stripe_token = nil
    raise ActiveRecord::RecordInvalid.new(user)
  rescue Stripe::CardError => e
    user.errors[:base] << e.message
    user.stripe_token = nil
    raise ActiveRecord::RecordInvalid.new(user)
  end

  # This works for create a user in Stripe
  def create_customer(user)
    customer = Stripe::Customer.create(
      :email  => user.email,
      # Add for test payment
      :source => user.stripe_token,
      # => if you are setting :plan, it seems will subscribed to a plan and charge automatically
      # :plan   => "oq_membership"
      # Add for test payment
      # :card => user.stripe_token
    )
  end

  def create_subscribe(customer)
    subscription = Stripe::Subscription.create(
    :customer   => customer.id,
    :plan       => "oq_membership"
    )
  end

  # This area for on time payment
  # def create_charge(customer)
  #   price = Rails.application.secrets.product_price
  #   title = Rails.application.secrets.product_title
  #   charge = Stripe::Charge.create(
  #     :customer    => customer.id,
  #     :amount      => "#{price}",
  #     :description => "#{title}",
  #     :currency    => "aud"
  #   )
  # end

end
