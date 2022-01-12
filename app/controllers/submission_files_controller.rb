class SubmissionFilesController < ApplicationController
  def show
    @submission_file = SubmissionFile.find(params[:id])
    File.open(@submission_file.sample.service.path_for(@submission_file.sample.key)) do |f|
      @similar = IqdbProxy.query_file(f).reject { |entry| entry[:submission].id == @submission_file.id }
    end
  end

  def update_e6_iqdb
    E6IqdbQueryWorker.perform_async params[:submission_file_id]
  end
end
