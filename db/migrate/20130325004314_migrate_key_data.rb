class MigrateKeyData < ActiveRecord::Migration
  def up
    keys = Key.all
    keys.each do |k|
      key_rel = KeyRelationship.new
      key_rel.key_id     = k.id
      key_rel.user_id    = k.user_id
      key_rel.project_id = k.project_id
      key_rel.created_at = k.created_at
      key_rel.save
    end
  end

  def down
  end
end
