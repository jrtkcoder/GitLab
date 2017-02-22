class Projects::TriggersController < Projects::ApplicationController
  before_action :authorize_admin_build!
  before_action :trigger, only: [:take, :edit, :update, :destroy]

  layout 'project_settings'

  def index
    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def create
    @trigger = project.triggers.create(create_params.merge(owner: current_user))

    if @trigger.valid?
      flash[:notice] = 'Trigger was created successfully.'
    else
      flash[:alert] = 'You could not create a new trigger.'
    end

    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def take
    if trigger.update(owner: current_user)
      flash[:notice] = 'Trigger was created successfully.'
    else
      flash[:alert] = 'You could not take ownership of trigger.'
    end

    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  def edit
  end

  def update
    if trigger.update(update_params)
      redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project), notice: 'Trigger was successfully updated.'
    else
      render action: "edit"
    end
  end

  def destroy
    if trigger.destroy
      flash[:notice] = "Trigger removed"
    else
      flash[:alert] = "You could not delete a new trigger"
    end

    redirect_to namespace_project_settings_ci_cd_path(@project.namespace, @project)
  end

  private

  def trigger
    @trigger ||= project.triggers.find(params[:id]) || render_404
  end

  def create_params
    params.require(:trigger).permit(:description)
  end

  def update_params
    params.require(:trigger).permit(:description)
  end
end
