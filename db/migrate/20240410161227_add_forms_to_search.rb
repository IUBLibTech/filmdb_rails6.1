class AddFormsToSearch < ActiveRecord::Migration[6.1]
  def change
    add_column :spread_sheet_searches, :form, :string
  end
end
