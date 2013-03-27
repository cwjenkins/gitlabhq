class DeployKeysController < ProjectResourceController
  respond_to :html

  # Authorize
  before_filter :authorize_admin_project!
  
  def index
    @keys = Key.deploy_keys
    @keys.each { |k| k.remove_dups @project }
  end

  def show
    @rel = KeyRelationship.find(params[:id])
    @key = @rel.key
  end

  def new
    @key = Key.new

    respond_with(@key)
  end

  def create
    @key = Key.new(params[:key])
    @key.project_ids = [@project.id]

    if @key.save
      redirect_to project_deploy_keys_path(@project)
    else
      render "new"
    end
  end

  def destroy
    @key = Key.find(params[:id])
    @key.destroy unless @key.has_relationships?

    respond_to do |format|
      format.html { redirect_to project_deploy_keys_url }
      format.js { render nothing: true }
    end
  end
end
