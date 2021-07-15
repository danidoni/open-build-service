class WorkflowStepsValidator < ActiveModel::Validator

  def validate(record)
    @scm_extractor_payload = record.scm_extractor_payload
    @workflow = record
  end

  private

  def valid_steps?
    unsupported_steps.none? && !invalid_steps?
  end

  def valid_workflow?
    raise Token::Errors::InvalidWorkflowStepDefinition, "Invalid workflow step definition: #{errors.to_sentence}" unless
      valid?
  end

  def unsupported_steps
    @unsupported_steps ||= @workflow.workflow_steps.each_with_object([]) do |step_definition, acc|
      rejected_steps = step_definition.reject { |step_name, _| Workflow::SUPPORTED_STEPS.key?(step_name) }
      rejected_steps.empty? ? acc : acc << rejected_steps
    end
  end

  def invalid_steps?
    @workflow.steps.reject(&:valid?).any?
  end

  def errors
    unsupported_steps.each_with_object([]) do |step_definition, acc|
      step_definition.each do |step_name, _|
        acc << "'#{step_name}' is not a supported step"
      end
      acc
    end
  end
end
