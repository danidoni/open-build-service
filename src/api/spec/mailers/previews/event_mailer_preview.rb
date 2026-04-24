# Preview all emails at http://localhost:3000/rails/mailers/event_mailer
class EventMailerPreview < ActionMailer::Preview
  def added_user_to_group
    event = Event::AddedUserToGroup.last || skip('No Event::AddedUserToGroup records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def appeal_created
    event = Event::AppealCreated.last || skip('No Event::AppealCreated records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def assignment_create
    event = Event::AssignmentCreate.last || skip('No Event::AssignmentCreate records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def assignment_delete
    event = Event::AssignmentDelete.last || skip('No Event::AssignmentDelete records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def build_fail
    event = Event::BuildFail.last || skip('No Event::BuildFail records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def cleared_decision
    event = Event::ClearedDecision.last || skip('No Event::ClearedDecision records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def comment_for_package
    event = Event::CommentForPackage.last || skip('No Event::CommentForPackage records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def comment_for_project
    event = Event::CommentForProject.last || skip('No Event::CommentForProject records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def comment_for_report
    event = Event::CommentForReport.last || skip('No Event::CommentForReport records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def comment_for_request
    event = Event::CommentForRequest.last || skip('No Event::CommentForRequest records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def favored_decision
    event = Event::FavoredDecision.last || skip('No Event::FavoredDecision records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def relationship_create
    event = Event::RelationshipCreate.last || skip('No Event::RelationshipCreate records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def relationship_delete
    event = Event::RelationshipDelete.last || skip('No Event::RelationshipDelete records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def removed_user_from_group
    event = Event::RemovedUserFromGroup.last || skip('No Event::RemovedUserFromGroup records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def report_for_comment
    event = Event::ReportForComment.last || skip('No Event::ReportForComment records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def report_for_package
    event = Event::ReportForPackage.last || skip('No Event::ReportForPackage records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def report_for_project
    event = Event::ReportForProject.last || skip('No Event::ReportForProject records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def report_for_user
    event = Event::ReportForUser.last || skip('No Event::ReportForUser records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def request_create
    event = Event::RequestCreate.last || skip('No Event::RequestCreate records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def request_statechange
    event = Event::RequestStatechange.last || skip('No Event::RequestStatechange records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def review_wanted
    event = Event::ReviewWanted.last || skip('No Event::ReviewWanted records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def upstream_package_version_changed
    event = Event::UpstreamPackageVersionChanged.last || skip('No Event::UpstreamPackageVersionChanged records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  def workflow_run_fail
    event = Event::WorkflowRunFail.last || skip('No Event::WorkflowRunFail records found')
    EventMailer.with(subscribers: subscribers_for(event), receiver_role: receiver_role_for(event), event: event).notification_email
  end

  private

  def subscribers_for(event)
    subscribers = event.subscribers
    subscribers.presence || [User.not_deleted.first]
  end

  def receiver_role_for(event)
    event.class.receiver_roles.first.to_s
  end
end
