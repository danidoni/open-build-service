class WorkflowRunFilterInputComponent < ApplicationComponent
  attr_accessor :text, :filter_item, :selected_input_filter, :placeholder

  def initialize(text:, filter_item:, selected_input_filter:, placeholder:)
    super

    @text = text
    @filter_item = filter_item
    @placeholder = placeholder
    @selected_input_filter = selected_input_filter
  end

  def css_for_filter_item
    'active' if @selected_input_filter.present?
  end

  def selected_filter_value
    @selected_input_filter
  end
end
