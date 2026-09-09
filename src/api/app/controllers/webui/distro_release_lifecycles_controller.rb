class Webui::DistroReleaseLifecyclesController < Webui::WebuiController
  #### Includes and extends

  #### Constants

  #### Self config

  #### Callbacks macros: before_action, after_action, etc.
  before_action :set_distro_release
  before_action :set_distro_release_lifecycle, only: %i[update destroy]
  # Pundit authorization policies control
  after_action :verify_authorized

  #### CRUD actions

  def create
    @distro_release_lifecycle = @distro_release.distro_release_lifecycles.new(distro_release_lifecycle_params)
    authorize @distro_release_lifecycle
    if @distro_release_lifecycle.save
      redirect_to distro_release_show_path, flash: { success: 'Lifecycle was successfully created.' }
    else
      redirect_to distro_release_show_path, flash: { error: "Lifecycle failed to create. #{@distro_release_lifecycle.errors.messages}" }
    end
  end

  def update
    authorize @distro_release_lifecycle
    if @distro_release_lifecycle.update(distro_release_lifecycle_params)
      redirect_to distro_release_show_path, flash: { success: 'Lifecycle was successfully updated.' }
    else
      redirect_to distro_release_show_path, flash: { error: "Lifecycle failed to update. #{@distro_release_lifecycle.errors.messages}" }
    end
  end

  def destroy
    authorize @distro_release_lifecycle
    @distro_release_lifecycle.destroy!
    redirect_to distro_release_show_path, flash: { success: 'Lifecycle was successfully destroyed.' }
  end

  #### Non CRUD actions

  #### Non actions methods
  # Use hide_action if they are not private

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_distro_release
    @distro_release = DistroRelease.find_by!(name: params.expect(:distro_release_name))
  end

  def set_distro_release_lifecycle
    @distro_release_lifecycle = @distro_release.distro_release_lifecycles.find_by!(name: params.expect(:lifecycle_name))
  end

  # Only allow a trusted parameter "white list" through.
  def distro_release_lifecycle_params
    params.expect(distro_release_lifecycle: %i[name date status])
  end

  # Lifecycles are rendered on the release page, they have no page of their own
  def distro_release_show_path
    distro_release_path(@distro_release.distro, @distro_release)
  end
end
