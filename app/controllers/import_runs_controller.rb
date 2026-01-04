class ImportRunsController < ApplicationController
  load_and_authorize_resource

  def index
    @import_runs = ImportRun.for_user(current_user).order(created_at: :desc).page(params[:page])
  end

  def show
  end

  def new
    #@import_run = current_user.organization.import_runs.new
  end

  def create
    ImportExport::ConfigResolver.resolve!(import_run_params[:resource])

    @import_run = current_user.organization.import_runs.create!(
      resource: import_run_params[:resource],
      user: current_user,
      status: :pending,
      file_name: import_run_params[:source_file]&.original_filename,
      source_file: import_run_params[:source_file]
    )

    ImportJob.perform_later(@import_run.id)

    redirect_to import_run_path(@import_run), notice: "Import został uruchomiony"
  rescue ArgumentError => e
    redirect_back fallback_location: import_runs_path, alert: e.message
  rescue StandardError => e
    redirect_back fallback_location: import_runs_path, alert: "Błąd: #{e.message}"
  end

  private

  def import_run_params
    params.require(:import_run).permit(:resource, :source_file)
  end

end
