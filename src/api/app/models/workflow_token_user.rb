class WorkflowTokenUser < ApplicationRecord
  belongs_to :user
  belongs_to :token, class_name: 'Token::Workflow'
end

# == Schema Information
#
# Table name: workflow_token_users
#
#  token_id :bigint           not null, indexed
#  user_id  :bigint           not null, indexed
#
# Indexes
#
#  index_workflow_token_users_on_token_id  (token_id)
#  index_workflow_token_users_on_user_id   (user_id)
#
