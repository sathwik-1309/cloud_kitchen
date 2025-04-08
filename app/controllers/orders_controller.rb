class OrdersController < ApplicationController

  def create
    customer_id = order_params[:customer_id]
    items = order_params[:items]
  
    if customer_id.blank? || !items.is_a?(Array) || items.empty?
      render json: { error: "customer_id and items are required" }, status: :bad_request
      return
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

    if customer_id.blank?
      return render json: { error: 'Customer ID is required' }, status: :bad_request
    end

    orders = OrderService.list_orders(customer_id, offset, limit)
    render json: orders, status: :ok
  end

  def show
    order = OrderService.find_order(params[:id])
    if order
      render json: order, status: :ok
    else
      render json: { error: 'Order not found' }, status: :not_found
    end
  end

  def destroy
    success = OrderService.cancel_order(params[:id])
    if success
      render json: { message: 'Order cancelled successfully' }, status: :ok
    else
      render json: { error: 'Unable to cancel order' }, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_id, items: [:inventory_item_id, :quantity])
  end
end