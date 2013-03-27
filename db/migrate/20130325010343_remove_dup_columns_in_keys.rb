class RemoveDupColumnsInKeys < ActiveRecord::Migration
  def up
    remove_column :keys, :created_at
    remove_column :keys, :user_id
    remove_column :keys, :project_id
  end

  def down
  end
end
