class CreateWorkflowStatusTemplates < ActiveRecord::Migration[4.2]
  def change
    create_table :workflow_status_templates do |t|
      t.string :name
      t.integer :sort_order
      t.text :description
      t.timestamps
    end


  end
end
