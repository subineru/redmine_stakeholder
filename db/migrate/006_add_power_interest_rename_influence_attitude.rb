class AddPowerInterestRenameInfluenceAttitude < ActiveRecord::Migration[5.2]
  def change
    # Add power and interest fields
    add_column :stakeholders, :power, :integer, default: 3
    add_column :stakeholders, :interest, :integer, default: 3

    # Rename influence_attitude to participation_degree
    rename_column :stakeholders, :influence_attitude, :participation_degree
  end
end
