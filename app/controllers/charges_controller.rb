class ChargesController < ApplicationController
  # skip_filter :scope_current_store, only: [:new, :create]
  before_filter :request_login, only: [:new]

  def checkout_options
    if logged_in?
      redirect_to new_charge_path(current_store)
    else
      session[:redirect_after_create] = new_charge_path(current_store)
      @customer = Customer.new
    end
  end

  def create_guest
    if params[:email] && params[:password]
      login(params[:email], params[:password], remember_me = false)
    else
      password = SecureRandom.hex(4)
      if customer = Customer.create(:email => params[:email],
        :first_name => params[:first_name], :last_name => params[:last_name],
        :password => password, :password_confirmation => password)
      else
        redirect_to :back, notice:"Sorry, that email has already been taken."
      end
      auto_login(customer)
    end
    redirect_to new_charge_path(current_store)
  end

  def new
    session[:return_to_url] = request.url
    @shipping_address = ShippingAddress.new
    @billing_address = Address.new
    @products = current_cart_products.map{|id,quantity|
                                          [Product.find(id), quantity]}
    @order_total = @products.reduce(0){|memo,(p,q)|memo+=(p.price*q)}
  end

  def create
    order = Order.for_customer(current_user, current_cart_products,
                               current_store.id)
    resque_process_stripe_charge(params, order)
    resque_order_confirmation_email(order)

    current_user.cart.destroy
    session[:shopping_cart].clear
    session[:return_to_url] = nil
    redirect_to orders_path,
      notice: "Order Received. You will receive confirmation processing."
  end

  private

  def resque_process_stripe_charge(params, order)
    Resque.enqueue(
      ProcessStripeCharge,
      current_user.email,
      params[:stripeToken],
      (order.total*100)
      )
  end

  def resque_order_confirmation_email(order)
    Resque.enqueue(
      OrderConfirmationEmail,
      current_store.id,
      current_user.id,
      order.id)
  end

end
