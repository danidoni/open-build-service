module Event
  class CreateReport < Base
    receiver_roles :moderator
    self.description = 'Report for a project, package, comment, user or request has been created'

    payload_keys :id, :user_id, :reportable_id, :reportable_type

    def parameters_for_notification
      super.merge(notifiable_type: 'Report')
    end
  end
end
