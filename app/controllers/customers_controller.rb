# app/controllers/customers_controller.rb
class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :update, :destroy]

  def index
    customers = Customer.all
    render json: customers, status: :ok
  end

  def show
    render json: @customer, status: :ok
  end

  def create
    customer = Customer.new(customer_params)
    if customer.save
      Mailer::WelcomeMailerWorker.perform_async(customer.id)
      render json: customer, status: :created
    else
      render json: { errors: customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @customer.update(customer_params)
      render json: @customer, status: :accepted
    else
      render json: { errors: @customer.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @customer.destroy
    head :no_content
  end

  private

  def set_customer
    @customer = Customer.find_by(id: params[:id])
    render json: { error: 'Customer not found' }, status: :not_found unless @customer
  end

  def customer_params
    params.require(:customer).permit(:name, :email)
  end
end