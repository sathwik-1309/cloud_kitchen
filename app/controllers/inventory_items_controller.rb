class InventoryItemsController < ApplicationController
  before_action :set_inventory_item, only: [:show, :update]

  def index
    inventory_items = InventoryItem.all
    render json: inventory_items, status: :ok
  end

  def show
    render json: @inventory_item, status: :ok
  end

  def create
    inventory_item = InventoryItem.new(inventory_item_params)
    if inventory_item.save
      Inventory::InventoryCheckWorker.perform_async(inventory_item.id)
      render json: inventory_item, status: :created
    else
      render json: { errors: inventory_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @inventory_item.update(inventory_item_params)
      Inventory::InventoryCheckWorker.perform_async(@inventory_item.id)
      render json: @inventory_item, status: :accepted
    else
      render json: { errors: @inventory_item.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # def destroy
  #   @inventory_item.destroy
  #   head :no_content
  # end

  private

  def set_inventory_item
    @inventory_item = InventoryItem.find_by(id: params[:id])
    return render json: { error: 'Inventory item not found' }, status: :not_found unless @inventory_item
  end

  def inventory_item_params
    params.require(:inventory_item).permit(:name, :quantity, :low_stock_threshold)
  end
end