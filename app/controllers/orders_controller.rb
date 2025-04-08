class OrdersController < ApplicationController
  before_action :set_order, only: [:show, :update, :destroy]

  def create
    customer_id = order_params[:customer_id]
    items = order_params[:items]

    if customer_id.blank? || Customer.exists?(id: customer_id) == false
      return render json: { error: "customer_id is invalid or nil" }, status: :bad_request
    end

    if !items.is_a?(Array) || items.empty?
      return render json: { error: "items are invalid or empty" }, status: :bad_request
    end
  
    result = OrderService.create_order(customer_id, items)
    if result[:success]
      render json: { order: result[:order] }, status: :created
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def index
    customer_id = params[:customer_id]
    offset = params[:offset] || 0
    limit = params[:limit] || 10

    if customer_id.blank? || !Customer.exists?(id: customer_id)
      return render json: { error: 'Customer ID is invalid or nil' }, status: :bad_request
    end

    orders = OrderService.list_orders(customer_id, offset, limit)
    render json: orders, status: :ok
  end

  def show
    render json: @order.get_hash, status: :ok
  end

  def update
    new_status = params[:status]
  
    unless new_status.present?
      return render json: { error: 'Status is required' }, status: :bad_request
    end

    if new_status == @order.status
      return render json: { error: 'Status is the same as current status' }, status: :unprocessable_entity
    end
  
    updated_order = OrderService.update_order_status(@order, new_status)
  
    if updated_order
      render json: updated_order.get_hash, status: :ok
    else
      render json: { error: 'Unable to update order' }, status: :unprocessable_entity
    end
  end

  def destroy
    success = OrderService.cancel_order(@order)
    if success
      render json: { message: 'Order cancelled successfully' }, status: :ok
    else
      render json: { error: 'Unable to cancel order' }, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = Order.find_by(id: params[:id])
    unless @order
      render json: { error: 'Order not found' }, status: :not_found
    end
  end

  def order_params
    params.require(:order).permit(:customer_id, items: [:inventory_item_id, :quantity])
  end
end