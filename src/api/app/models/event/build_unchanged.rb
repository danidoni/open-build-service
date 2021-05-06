module Event
  class BuildUnchanged < Build
    self.message_bus_routing_key = 'package.build_unchanged'
    self.description = 'Package has succeeded building with unchanged result'

    def state
      'unchanged'
    end
  end
end

# == Schema Information
#
# Table name: events
#
#  id          :integer          not null, primary key
#  eventtype   :string(255)      not null, indexed
#  mails_sent  :boolean          default(FALSE), indexed
#  payload     :text(65535)
#  undone_jobs :integer          default(0)
#  created_at  :datetime         indexed
#  updated_at  :datetime
#  package_id  :integer          indexed
#
# Indexes
#
#  index_events_on_created_at  (created_at)
#  index_events_on_eventtype   (eventtype)
#  index_events_on_mails_sent  (mails_sent)
#  index_events_on_package_id  (package_id)
#
