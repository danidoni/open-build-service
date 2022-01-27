class WorkflowArtifactsPerStep < ApplicationRecord
  belongs_to :workflow_run, optional: false

  serialize :artifacts, JSON

  validates :step, :artifacts, presence: true
end

# == Schema Information
#
# Table name: workflow_artifacts_per_steps
#
#  id              :integer          not null, primary key
#  artifacts       :text(65535)
#  step            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  workflow_run_id :integer          not null, indexed
#
# Indexes
#
#  index_workflow_artifacts_per_steps_on_workflow_run_id  (workflow_run_id)
#
