class Token::Rebuild < Token
  def self.token_name
    'rebuild'
  end

  def rebuild
    rebuild_trigger = PackageControllerService::RebuildTrigger.new(package: @pkg, project: @prj, params: params)
    authorize rebuild_trigger.policy_object, :update?
    rebuild_trigger.rebuild?
    render_ok
  end
end

# == Schema Information
#
# Table name: tokens
#
#  id         :integer          not null, primary key
#  string     :string(255)      indexed
#  type       :string(255)
#  package_id :integer          indexed
#  user_id    :integer          not null, indexed
#
# Indexes
#
#  index_tokens_on_string  (string) UNIQUE
#  package_id              (package_id)
#  user_id                 (user_id)
#
# Foreign Keys
#
#  tokens_ibfk_1  (user_id => users.id)
#  tokens_ibfk_2  (package_id => packages.id)
#
