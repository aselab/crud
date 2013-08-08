$(function() {
  $(document).on("click", "a[data-toggle='modal-form']", function() {
    var a = $(this);
    $.ajax({
      method: "GET",
      url: a.attr("href"),
      success: function(data) {
        a.after(data);
        a.attr("data-action", $("#modal_form form").attr("action"));
      }
    });
    return false;
  });
});
