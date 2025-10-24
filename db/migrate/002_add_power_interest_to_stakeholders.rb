class AddPowerInterestToStakeholders < ActiveRecord::Migration[5.2]
  def change
    add_column :stakeholders, :power_level, :integer, default: 3
    add_column :stakeholders, :interest_level, :integer, default: 3
  end
end
