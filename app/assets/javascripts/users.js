var setupButtons = function() {
  $('.button-primary').click(function() {
    $(this).html('Loading...');
    $(this).attr("disabled", "disabled");
  });
}

$(document).ready(setupButtons);
$(window).bind('page:change', setupButtons);