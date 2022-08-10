class RequestDecisionComponent < ApplicationComponent
  def initialize(bs_request:, actions:, is_target_maintainer:, is_author:)
    super

    @bs_request = bs_request
    @actions = actions
    @is_target_maintainer = is_target_maintainer
    @action = @actions.first
    @is_author = is_author
  end

  def render?
    can_handle_request?
  end

  def single_action_request
    @actions.count == 1
  end

  # TODO: Move all those "can_*" checks to a pundit policy
  def can_handle_request?
    @bs_request.state.in?([:new, :review, :declined]) && (@is_target_maintainer || @is_author)
  end

  def can_revoke_request?
    @is_author && @bs_request.state.in?([:new, :review, :declined])
  end

  def can_accept_request?
    @bs_request.state.in?([:new, :review]) && @is_target_maintainer
  end

  def can_decline_request?
    !@is_author
  end

  def can_reopen_request?
    @bs_request.state == :declined
  end
end
