# Gather event receivers for a receiver role
#   An event receiver is a user/group wanting to be notified about an event
#   A receiver role is defined on the event itself. It could be a maintainer, bugowner, etc...
class EventReceiversGatherer
  attr_reader :event

  def initialize(event, receiver_role)
    @event = event
    @receivers_without_group_members = event.send("#{receiver_role}s")
  end

  def call
    gather_event_receivers(@event, @receivers_without_group_members)
  end

  private

  def gather_event_receivers(event, receivers_without_group_members)
    receivers = []

    receivers_without_group_members.each do |receiver|
      case receiver
      when User
        receivers << receiver
      when Group
        receivers << receiver if receiver.email.present?
        receivers += receiver.email_users
      end
    end

    receivers
  end
end
