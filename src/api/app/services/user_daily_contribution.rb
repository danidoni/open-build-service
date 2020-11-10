class UserDailyContribution
  attr_accessor :user, :date

  def initialize(user, date)
    @user = user
    @date = date
  end

  def call
    { comments: comments_for_date,
      requests_reviewed: reviews_done_per_day,
      commits: commits_done_per_day,
      requests_created: requests_created_for_date }
  end

  private

  def requests_created_for_date
    user.requests_created.where('date(created_at) = ?', date).pluck(:number)
  end

  def comments_for_date
    user.comments.where('date(created_at) = ?', date).count
  end

  def reviews_done_per_day
    Review.where(reviewer: user.login, state: [:accepted, :declined])
          .where('date(reviews.created_at) = ?', date)
          .joins(:bs_request)
          .group('bs_requests.number')
          .order('count_id DESC, bs_requests_number')
          .count(:id)
  end

  def commits_done_per_day
    counts = Hash.new(0)
    packages = {}
    user.commit_activities.where(date: date).pluck(:project, :package, :count).each do |e|
      packages[e[0]] ||= []
      packages[e[0]] << [e[1], e[2]]
      counts[e[0]] += e[2]
    end
    counts.sort_by { |_, b| -b }.map { |project, count| [project, packages[project], count] }
  end
end
