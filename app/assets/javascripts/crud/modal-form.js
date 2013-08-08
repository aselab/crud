$(function() {
  $(document).on("click", "a[data-toggle='modal-form']", function() {
    var a = $(this);
    $.get(a.attr("href"), function(data) {
      $(document.body).append(data);
      a.attr("data-action", $("#modal_form form").attr("action"));
    });
    return false;
  });
});
