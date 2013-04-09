class MigrateKeyData < ActiveRecord::Migration
  def up
    execute "INSERT INTO key_relationships (key_id, user_id, project_id, created_at) SELECT id, user_id, project_id, created_at FROM `keys`"
  end

  def down
    execute "INSERT INTO `keys` (id, user_id, project_id, created_at) SELECT key_id, user_id, project_id, created_at FROM key_relationships"
  end
end
