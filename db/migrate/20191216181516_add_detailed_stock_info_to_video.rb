class AddDetailedStockInfoToVideo < ActiveRecord::Migration[4.2]
  def change
    add_column :videos, :detailed_stock_information, :text
  end
end
