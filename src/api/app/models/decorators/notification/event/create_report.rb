class Decorators::Notification::Event::CreateReport < Decorators::Notification::Common
  def description_text
    "'#{notification.notifiable.user.login}' created a report for a #{notification.event_payload['reportable_type'].downcase}. This is the reason:"
  end

  # TODO: Remove `Event::CreateReport` after all existing records are migrated to the new STI classes
  def notifiable_link_text(_helpers)
    "Report for a #{notification.event_payload['reportable_type']}"
  end

  # TODO: Remove `Event::CreateReport` after all existing records are migrated to the new STI classes
  def notifiable_link_path
    reportable = notification.notifiable.reportable
    link_for_reportables(reportable)
  end

  private

  # TODO: Remove `Event::CreateReport` after all existing records are migrated to the new STI classes. This method is also used by 'Event::ClearedDecision' and 'Event::FavoredDecision', this need to
  # be adapted
  def link_for_reportables(reportable)
    return '#' unless reportable

    case notification.event_payload['reportable_type']
    when 'Comment'
      link_for_commentables_on_reportables(commentable: reportable.commentable)
    when 'Package'
      Rails.application.routes.url_helpers.package_show_path(package: reportable,
                                                             project: reportable.project,
                                                             notification_id: notification.id,
                                                             anchor: 'comments-list')
    when 'Project'
      Rails.application.routes.url_helpers.project_show_path(reportable, notification_id: notification.id, anchor: 'comments-list')
    when 'User'
      Rails.application.routes.url_helpers.user_path(reportable)
    end
  end

  def link_for_commentables_on_reportables(commentable:)
    case commentable
    when BsRequest
      Rails.application.routes.url_helpers.request_show_path(commentable.number, notification_id: notification.id, anchor: 'comments-list')
    when BsRequestAction
      Rails.application.routes.url_helpers.request_show_path(number: commentable.bs_request.number, request_action_id: commentable.id,
                                                             notification_id: notification.id, anchor: 'tab-pane-changes')
    when Package
      Rails.application.routes.url_helpers.package_show_path(package: commentable,
                                                             project: commentable.project,
                                                             notification_id: notification.id,
                                                             anchor: 'comments-list')
    when Project
      Rails.application.routes.url_helpers.project_show_path(commentable, notification_id: notification.id, anchor: 'comments-list')
    end
  end
end
