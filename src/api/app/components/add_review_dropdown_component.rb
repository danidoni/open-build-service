class AddReviewDropdownComponent < ApplicationComponent
  attr_accessor :can_add_reviews, :my_open_reviews

  def initialize(bs_request:, user:, can_add_reviews:, my_open_reviews:)
    super

    @bs_request = bs_request
    @user = user
    @can_add_reviews = can_add_reviews
    @my_open_reviews = my_open_reviews
  end

  def render?
    can_add_reviews && my_open_reviews.present?
  end
end
