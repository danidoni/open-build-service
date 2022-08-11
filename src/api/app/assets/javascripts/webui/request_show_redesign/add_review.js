$(document).ready(function() {
  $('#add-review-component .dropdown-item').on('click', function(e) {
    const review = $(this);

    $('#review_form_collapse h5 i').html(review.html());
    $('#review_id').val(review.data('review'));
  });

  // TODO: Hide collapse element when the other is displayed
  //       like hide `review_form_collapse` when `decision_review_form_collapse` is shown and vice-versa
});
