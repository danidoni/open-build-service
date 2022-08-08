class AddReviewInlineFormComponent < ApplicationComponent
  with_collection_parameter :review
  attr_accessor :review

  def initialize(review:)
    super

    @review = review
  end
end
