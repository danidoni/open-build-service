class WorkflowTokenUser < ApplicationRecord
  belongs_to :user
  belongs_to :token, class_name: 'Token::Workflow'
end