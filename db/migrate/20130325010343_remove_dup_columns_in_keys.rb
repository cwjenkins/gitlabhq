class RemoveDupColumnsInKeys < ActiveRecord::Migration
  def up
    remove_column :keys, :created_at
    remove_column :keys, :user_id
    remove_column :keys, :project_id
  end

  def down
    add_column :keys, :created_at, :timestamp
    add_column :keys, :user_id, :integer
    add_column :keys, :project_id, :integer
  end
end
