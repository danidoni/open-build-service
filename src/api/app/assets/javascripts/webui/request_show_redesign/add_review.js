$(document).ready(function(e) {
  $('#add-review-component .dropdown-item').on('click', function(e) {
    const review = $(this);

    $('#review_form_collapse h5 i').html(review.html());
    $('#review_id').val(review.data('review'));
  });

  $('#add-review-component').on('shown.bs.dropdown', function () {
    $('#review_form_collapse').collapse('hide');
  })
});

$(document).click(function(e) {
  const reviewCollapsible = document.getElementById('review_form_collapse');
  if (!reviewCollapsible.contains(e.target)) {
    	$('.collapse').collapse('hide');
  }
});
