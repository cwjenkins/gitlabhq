class AddKeyRelationships < ActiveRecord::Migration
  def up
    create_table :key_relationships do |t|
      t.integer   :key_id, :null => false
      t.integer   :user_id
      t.integer   :project_id
      t.timestamp :created_at, :null => false
    end
  end

  def down
  end
end
