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
      workflow_filters = event_subscription.payload[:workflow_filters]

      if report_for_repository?(event.payload['repository'], workflow_filters) && report_for_architecture?(event.payload['architecture'], workflow_filters)
        SCMStatusReporter.new(event.payload,
                              event_subscription.payload,
                              event_subscription.token.scm_token,
                              event_subscription.eventtype).call
      end
    end

    true
  end

  private

  def report_for_repository?(event_repository, filters)
    return true if filters.blank?

    return true if filters[:repositories][:only]&.include?(event_repository)

    return true if filters[:repositories][:ignore]&.exclude?(event_repository)

    false
  end

  def report_for_architecture?(event_architecture, filters)
    return true if filters.blank?

    return true if filters[:architectures][:only]&.include?(event_architecture)

    return true if filters[:architectures][:ignore]&.exclude?(event_architecture)

    false
  end
end
