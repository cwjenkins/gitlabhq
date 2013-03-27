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
  has_one  :key_relationship
  has_one  :user, :through => :key_relationship
  delegate :user_id, :to => :key_relationship

  #DeployKey
  has_many :key_relationships 
  has_many :projects, :through => :key_relationships
  before_destroy :no_relationships?

  scope :deploy_keys, Key.joins(:key_relationships).where('key_relationships.project_id IS NOT NULL').group(:key_id)

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
    user.nil? && key_relationships[0].project.present?
  end

  def projects
    if is_deploy_key
      key_relationships.each { |r| r.project }
    else
      user.authorized_projects
    end
  end

  def has_relationships?
    !no_relationships?
  end

  def no_relationships?
    Key.joins(:key_relationships).where('key_id=?',self.id).count() == 0
  end

  def created_at
      key_relationship.created_at
  end

  #Select only one relationship for each deploy key. 
  #If the current project has a deploy key show it instead of another
  def remove_dups project
      if project_ids.include? project.id
        key_relationships.select! { |r| r.project_id == project.id }
      else
        #This deploy key isn't related to the current project so just pick the first one.
        first_id = key_relationships[0].project_id 
        key_relationships.select! { |r| r.project_id == first_id }
      end
  end

  def shell_id
    "key-#{self.id}"
  end
end
