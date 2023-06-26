class AddWorkflowConfigurationYamlAndNamesToWorkflowRuns < ActiveRecord::Migration[7.0]
  def change
    add_column :workflow_runs, :workflow_configuration_yaml, :text
    add_column :workflow_runs, :workflow_configuration_names, :string
  end
end
