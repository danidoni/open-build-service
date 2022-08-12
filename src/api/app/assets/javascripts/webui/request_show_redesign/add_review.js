$(document).ready(function(e) {
  $('#add-review-component .dropdown-item').on('click', function(e) {
    const review = $(this);

    $('#review_form_collapse h5 i').html(review.html());
    $('#review_id').val(review.data('review'));
  });

});

$(document).click(function(e) {
	if (!$(e.target).is('#review_form_collapse')) {
    	$('.collapse').collapse('hide');
  }
});
