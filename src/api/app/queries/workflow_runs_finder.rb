class WorkflowRunsFinder
  EVENT_TYPE_MAPPING = {
    'pull_request' => ['pull_request', 'Merge Request Hook'],
    'push' => ['push', 'Push Hook'],
    'tag_push' => ['push', 'Tag Push Hook']
  }.freeze

  def initialize(relation = WorkflowRun.all)
    @initial_relation = relation
    @relation = relation.includes([:token]).order(created_at: :desc)
  end

  def reset
    @relation = @initial_relation

    self
  end

  def all
    @relation.all
  end

  def group_by_generic_event_type
    EVENT_TYPE_MAPPING.to_h do |key, _value|
      [key, with_generic_event_type(key).count]
    end
  end

  def with_generic_event_type(generic_event_types, request_action = [])
    return self if generic_event_types.empty?

    generic_event_types = [generic_event_types] unless generic_event_types.is_a?(Array)
    first_event_type, other_event_types = generic_event_types

    # The first event type needs to be AND'ed with the rest of the relations
    query = case first_event_type
            when 'tag_push'
              "request_headers LIKE '%: Tag Push Hook%' OR JSON_EXTRACT(request_payload, '$.ref') LIKE '%refs/tags/%'"
            when 'push'
              "request_headers LIKE '%: Push Hook%' OR JSON_EXTRACT(request_payload, '$.ref') LIKE '%refs/heads/%'"
            else
              EVENT_TYPE_MAPPING[first_event_type].map do |event_type|
                "request_headers LIKE '%: #{event_type}%'"
              end.join(' OR ')
            end

    @relation = @relation.where(query)

    if request_action.any? && first_event_type == 'pull_request'
      @relation = @relation.where("JSON_EXTRACT(request_payload, '$.action') = (?) OR JSON_EXTRACT(request_payload, '$.object_attributes.action') = (?)", request_action,
                                  request_action)
    end

    return self if other_event_types.nil?

    other_event_types = [other_event_types] unless other_event_types.is_a?(Array)

    # The rest of the event types need to be OR'ed against the first event type
    @relation = other_event_types.inject(@relation) do |local_relation, other_event_type|
      query = case other_event_type
              when 'tag_push'
                "request_headers LIKE '%: Tag Push Hook%' OR JSON_EXTRACT(request_payload, '$.ref') LIKE '%refs/tags/%'"
              when 'push'
                "request_headers LIKE '%: Push Hook%' OR JSON_EXTRACT(request_payload, '$.ref') LIKE '%refs/heads/%'"
              else
                EVENT_TYPE_MAPPING[other_event_type].map do |event_type|
                  "request_headers LIKE '%: #{event_type}%'"
                end.join(' OR ')
              end

      local_relation = local_relation.or(@initial_relation.where(query))

      if request_action.any? && other_event_type == 'pull_request'
        local_relation = local_relation.where("JSON_EXTRACT(request_payload, '$.action') = (?) OR JSON_EXTRACT(request_payload, '$.object_attributes.action') = (?)", request_action,
                                              request_action)
      end

      local_relation
    end

    self
  end

  def with_event_source_name(event_source_name, filter)
    return self if event_source_name.blank?

    hook_events_array = case filter
                        when 'commit'
                          # Both push and tag_push related events deal with commit sha.
                          (EVENT_TYPE_MAPPING['push'] + EVENT_TYPE_MAPPING['tag_push']).uniq
                        when 'pr_mr'
                          EVENT_TYPE_MAPPING['pull_request']
                        else
                          []
                        end
    @relation = @relation.where(event_source_name: event_source_name, hook_event: hook_events_array)

    self
  end

  def with_status(statuses)
    statuses = [statuses] unless statuses.is_a?(Array)
    return self if statuses.empty?

    @relation = @relation.where(status: statuses)

    self
  end

  def succeeded
    with_status('success')
  end

  def running
    with_status('running')
  end

  def failed
    with_status('fail')
  end

  def count
    @relation.count
  end
end
