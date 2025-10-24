class CreateStakeholders < ActiveRecord::Migration[5.2]
  def change
    create_table :stakeholders do |t|
      t.integer :project_id, null: false
      t.string :name, null: false
      t.string :impact_phase
      t.text :requirements
      t.text :expectations
      t.string :support_level
      t.integer :position, default: 1

      t.timestamps
    end

    add_index :stakeholders, :project_id
    add_index :stakeholders, [:project_id, :position]
  end
end
