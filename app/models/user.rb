class User < ActiveRecord::Base
  enum role: [:user, :vip, :admin]
  after_initialize :set_default_role, :if => :new_record?
  before_create :make_payment, unless: Proc.new { |user| user.admin? }
  after_create :sign_up_for_mailing_list
  attr_accessor :stripe_token

  def set_default_role
    self.role ||= :user
  end

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def make_payment
    MakePaymentService.new.perform(self)
  end

  def sign_up_for_mailing_list
    MailingListSignupJob.perform_later(self)
  end

  def subscribe
    mailchimp = Gibbon::Request.new(api_key: Rails.application.secrets.mailchimp_api_key)
    list_id = Rails.application.secrets.mailchimp_list_id
    result = mailchimp.lists(list_id).members.create(
      body: {
        email_address: self.email,
        status: 'subscribed',
        merge_fields: {
          FNAME: self.first_name,
          LNAME: self.last_name
        }
    })
    Rails.logger.info("Subscribed #{self.email} to MailChimp") if result
  end

end
