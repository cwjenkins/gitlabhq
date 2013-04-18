# == Schema Information
#
# Table name: keys
#
#  id         :integer          not null, primary key
#  updated_at :datetime         not null
#  key        :text
#  title      :string(255)
#  identifier :string(255)
#

require 'digest/md5'

class Key < ActiveRecord::Base
  attr_accessible :key, :title, :project_ids

  #UserKey
  has_one  :user_relationship, class_name: "KeyRelationship"
  has_one  :user, :through => :user_relationship
  delegate :user_id, :to => :user_relationship

  #DeployKey
  has_many :project_relationships, class_name: "KeyRelationship"
  has_many :projects, :through => :project_relationships
  before_destroy :no_relationships?

  scope :user_keys,       Key.joins(:user_relationship).where('key_relationships.project_id IS NULL').group(:key_id)
  scope :deploy_keys,     Key.joins(:project_relationships).where('key_relationships.user_id IS NULL').group(:key_id)
  scope :unassigned_keys, Key.where("NOT EXISTS (select * from key_relationships r where r.key_id=`keys`.id)")

  before_validation :strip_white_space

  validates :title, presence: true, length: { within: 0..255 }
  validates :key, presence: true, length: { within: 0..5000 }, format: { :with => /ssh-.{3} / }, uniqueness: true
  validate :fingerprintable_key

  delegate :name, :email, to: :user, prefix: true

  def strip_white_space
    self.key = self.key.strip unless self.key.blank?
  end

  def fingerprintable_key
    return true unless key # Don't test if there is no key.

    file = Tempfile.new('key_file')
    begin
      file.puts key
      file.rewind
      fingerprint_output = `ssh-keygen -lf #{file.path} 2>&1` # Catch stderr.
    ensure
      file.close
      file.unlink # deletes the temp file
    end
    errors.add(:key, "can't be fingerprinted") if $?.exitstatus != 0
  end

  def is_deploy_key
    project_relationships.any?
  end

  def no_relationships?
    project_relationships.empty?
  end

  def created_at
    (user_relationship && user_relationship.created_at || updated_at)
  end

  def projects
    if is_deploy_key
      project_relationships.each { |r| r.project }
    else
      user = User.find 1
      user.authorized_projects
    end
  end

  def available_for? project_id
    projects.find(project_id).present?
  end

  #Select only one relationship for each deploy key. 
  #If the current project has a deploy key show it instead of another
  def remove_dups project
      if project_ids.include? project.id
        project_relationships.select! { |r| r.project_id == project.id }
      else
        #This deploy key isn't related to the current project so just pick the first one.
        first_id = key_relationships[0].project_id 
        project_relationships.select! { |r| r.project_id == first_id }
      end
  end

  def self.mass_update params
    key_ids          = params['key']['ids'][0].split(',')  
    related_ids      = params['isDeployKeys'] ? 'project_ids' : 'user_id'

    key_ids.each { |key_id|
      key              = Key.find key_id
      existing_ids     = key.send(related_ids)
      add_ids          = params['add']['key-' + key_id][0].split(',').map(&:to_i)
      remove_ids       = params['remove']['key-' + key_id][0].split(',').map(&:to_i)
      update_ids       = ((existing_ids + add_ids) - remove_ids)
      key.update_attributes(related_ids => update_ids)
    }
  end

  def shell_id
    "key-#{self.id}"
  end
end
