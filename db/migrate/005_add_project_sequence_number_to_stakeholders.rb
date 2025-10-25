class AddProjectSequenceNumberToStakeholders < ActiveRecord::Migration[5.2]
  def change
    add_column :stakeholders, :project_sequence_number, :integer, default: 0, null: false
    add_index :stakeholders, [:project_id, :project_sequence_number], unique: true

    # Populate existing stakeholders with project_sequence_number
    # Group by project_id and assign sequential numbers
    Stakeholder.find_each do |stakeholder|
      next if stakeholder.project_sequence_number != 0

      # Count how many stakeholders already have sequence numbers in this project
      count = Stakeholder.where(project_id: stakeholder.project_id)
                        .where("project_sequence_number > ?", 0)
                        .count

      stakeholder.update_column(:project_sequence_number, count + 1)
    end
  end
end
