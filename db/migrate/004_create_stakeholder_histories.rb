class CreateStakeholderHistories < ActiveRecord::Migration[5.2]
  def change
    create_table :stakeholder_histories do |t|
      # 關聯字段
      t.integer :stakeholder_id, null: false
      t.integer :user_id, null: false

      # 操作信息
      t.string :action, null: false, limit: 50  # create, update, delete
      t.string :field_name, limit: 255          # 修改的欄位名稱（如果有的話）

      # 變更值
      t.text :old_value                         # 修改前的值
      t.text :new_value                         # 修改後的值

      t.timestamps
    end

    # 添加索引以提高查詢效率
    add_index :stakeholder_histories, :stakeholder_id
    add_index :stakeholder_histories, :user_id
    add_index :stakeholder_histories, :created_at
    add_index :stakeholder_histories, [:stakeholder_id, :created_at]
  end
end
