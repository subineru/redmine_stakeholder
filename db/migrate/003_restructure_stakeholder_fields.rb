class RestructureStakeholderFields < ActiveRecord::Migration[5.2]
  def up
    # Remove old fields
    remove_column :stakeholders, :impact_phase
    remove_column :stakeholders, :requirements
    remove_column :stakeholders, :expectations
    remove_column :stakeholders, :support_level
    remove_column :stakeholders, :power_level
    remove_column :stakeholders, :interest_level

    # Add new fields
    add_column :stakeholders, :title, :string
    add_column :stakeholders, :location_type, :string # internal/external
    add_column :stakeholders, :project_role, :string
    add_column :stakeholders, :primary_needs, :text
    add_column :stakeholders, :expectations, :text
    add_column :stakeholders, :influence_attitude, :string
  end

  def down
    # Remove new fields
    remove_column :stakeholders, :title
    remove_column :stakeholders, :location_type
    remove_column :stakeholders, :project_role
    remove_column :stakeholders, :primary_needs
    remove_column :stakeholders, :expectations
    remove_column :stakeholders, :influence_attitude

    # Restore old fields
    add_column :stakeholders, :impact_phase, :string
    add_column :stakeholders, :requirements, :text
    add_column :stakeholders, :expectations, :text
    add_column :stakeholders, :support_level, :string
    add_column :stakeholders, :power_level, :integer, default: 3
    add_column :stakeholders, :interest_level, :integer, default: 3
  end
end
