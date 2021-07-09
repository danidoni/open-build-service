# We don't properly capitalize SCM in the class name since CreateJob is doing `CLASS_NAME.to_s.camelize.safe_constantize`
class ReportToScmJob < CreateJob
  ALLOWED_EVENTS = ['Event::BuildFail', 'Event::BuildSuccess'].freeze

  queue_as :scm

  def perform(event_id)
    event = Event::Base.find(event_id)
    return false unless event.undone_jobs.positive?

    event_type = event.eventtype
    return false unless ALLOWED_EVENTS.include?(event_type)

    event_package = Package.find_by_project_and_name(event.payload['project'], Package.striping_multibuild_suffix(event.payload['package']))
    return false if event_package.blank?

    EventSubscriptionsFinder.new
                            .for_scm_channel_with_token(event_type: event_type, event_package: event_package)
                            .each do |event_subscription|
      workflow_filters = event_subscription.payload.with_indifferent_access[:workflow_filters] || {}

      next unless report_for_repository?(event.payload['repository'], workflow_filters[:repositories])
      next unless report_for_architecture?(event.payload['arch'], workflow_filters[:architectures])

      SCMStatusReporter.new(event.payload,
                            event_subscription.payload,
                            event_subscription.token.scm_token,
                            event_subscription.eventtype).call
    end
    true
  end

  private

  def report_for_repository?(event_repository, repository_filters)
    return true if repository_filters.blank?

    return true if repository_filters[:only]&.include?(event_repository)

    return true if repository_filters[:ignore]&.exclude?(event_repository)

    false
  end

  def report_for_architecture?(event_architecture, architecture_filters)
    return true if architecture_filters.blank?

    return true if architecture_filters[:only]&.include?(event_architecture)

    return true if architecture_filters[:ignore]&.exclude?(event_architecture)

    false
  end
end
