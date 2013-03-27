# == Schema Information
#
# Table name: key_relationships
#
#  id         :integer          not null, primary key
#  key_id     :integer          not null
#  user_id    :integer
#  project_id :integer
#  created_at :timestamp        not null
# 

class KeyRelationship < ActiveRecord::Base
  attr_accessible :key_id, :user_id, :project_id
  belongs_to :key, :dependent => :destroy
  belongs_to :project
  belongs_to :user
end
