class ChangeOfferStatusToString < ActiveRecord::Migration[8.1]
  def change
    def up
      change_column :offers, :status, :string
    end

    def down
      change_column :offers, :status, :integer
    end
  end
end
