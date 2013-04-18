class Admin::KeysController < Admin::ApplicationController

  def index
    @user_keys       = Key.user_keys.order("keys.title ASC").page(params[:user_keys_page]).per(5)
    @deploy_keys     = Key.deploy_keys.order("keys.title ASC").page(params[:deploy_keys_page]).per(5)
    @unassigned_keys = Key.unassigned_keys.order("keys.title ASC").page(params[:unassigned_keys_page]).per(5)

    @projects        = Project.order("projects.name ASC").page(params[:projects_page]).per(5)
    @users           = User.order("users.name ASC").page(params[:users_page]).per(5)
  end

  def show
    @key = Key.find(params[:id])
  end

  def new
    @key = Key.new
  end

  def create
   Key.create(params[:key])

   redirect_to admin_keys_path
  end

  def mass_update
    Key.mass_update(params)   

    redirect_to admin_keys_path
  end

  def destroy
    key = Key.find(params[:id])
    
    if key.is_deploy_key
      key.project_relationships.each { |r| r.destroy }
    else
      key.user_relationship.destroy
    end   
 
    key.destroy

    redirect_to admin_keys_path
  end

end
