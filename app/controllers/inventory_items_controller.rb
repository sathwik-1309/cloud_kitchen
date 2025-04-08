class InventoryItemsController < ApplicationController
  before_action :set_inventory_item, only: [:show, :update, :destroy]

  def index
    inventory_items = InventoryItem.all
    render json: inventory_items
  end

  def show
    render json: @inventory_item
  end

  def create
    inventory_item = InventoryItem.new(inventory_item_params)
    if inventory_item.save
      render json: inventory_item, status: :created
    else
      render json: { errors: inventory_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @inventory_item.update(inventory_item_params)
      render json: @inventory_item
    else
      render json: { errors: @inventory_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @inventory_item.destroy
    head :no_content
  end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find_by(id: params[:id])
    return render json: { error: 'Inventory item not found' }, status: :not_found unless @inventory_item
  end

  def inventory_item_params
    params.require(:inventory_item).permit(:name, :quantity, :low_stock_threshold)
  end
end