class AddPurchasePriceToVariants < ActiveRecord::Migration[8.1]
  def change
    add_column :variants, :purchase_price, :decimal, precision: 10, scale: 2
  end
end
