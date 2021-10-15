module Webui::MainHelper
  MAX_LENGTH = 35
  SUBSTRING_LENGTH = 5

  def icon_for_status(message)
    case message.severity.to_sym
    when :green
      { class: 'fa-check-circle text-success', title: 'Success' }
    when :yellow
      { class: 'fa-exclamation-triangle text-warning', title: 'Warning' }
    when :red
      { class: 'fa-exclamation-circle text-danger', title: 'Alert' }
    when :announcement
      { class: 'fa-bullhorn text-info', title: 'Announcement' }
    else
      { class: 'fa-info-circle text-info', title: 'Info' }
    end
  end

  def truncate_in_the_middle(string)
    if string.length > MAX_LENGTH
      "#{string[0..SUBSTRING_LENGTH]}..#{string[string.length - SUBSTRING_LENGTH, string.length]}"
    else
      string
    end
  end
end
