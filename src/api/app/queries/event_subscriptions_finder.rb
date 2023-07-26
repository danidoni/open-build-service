class EventSubscriptionsFinder
  def initialize(relation = EventSubscription.all, event_package_or_request:)
    if event_package_or_request.is_a(Package)
      @relation = relation.where(package: event_package_or_request)
    else
      @relation = relation.where(bs_request: event_package_or_request)
    end
  end

  def for_scm_channel_with_token(event_type:)
    @relation
      .where(eventtype: event_type,
             channel: :scm)
      .where.not(token_id: nil)
  end
end
