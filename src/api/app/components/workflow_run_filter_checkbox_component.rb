class WorkflowRunFilterCheckboxComponent < ApplicationComponent
  def initialize(text:, filter_item:, selected_filter:, amount:, icon: '')
    super

    @text = text
    @sanitized_key = text.parameterize.underscore
    @filter_item = filter_item
    @selected_filter = selected_filter
    @amount = amount || 0
    @icon = icon
  end

  def icon_tag
    tag.i(class: ['me-1', @icon]) if @icon != ''
  end

  private

  def workflow_run_filter_matches?
    if @selected_filter[:status].present?
      @filter_item[:status] == @selected_filter[:status]
    elsif @selected_filter[:generic_event_type].present?
      @filter_item[:generic_event_type] == @selected_filter[:generic_event_type]
    elsif @selected_filter.empty?
      @filter_item.empty?
    end
  end
end
