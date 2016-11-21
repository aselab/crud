(function($){
  $.fn.crudSelect2 = function(options) {
    if (!options) options = {};
    var defaultOptions = {
      searchKey: "term",
      labelMethod: "name",
      allowClear: true
    };
    if (options.url) {
      defaultOptions.ajax = {
        url: options.url,
        dataType: "json",
        delay: 300,
        cache: true,
        data: function(params) {
          var data = {page: params.page};
          data[options.searchKey] = params.term;
          return data;
        },
        processResults: function(d, params) {
          $(d.items).each(function() { this.text = this[options.labelMethod]; });
          var currentPage = params.page || 1;
          return {results: d.items, pagination: {more: currentPage < d.meta.total_pages}};
        }
      };
    }
    options = $.extend(true, defaultOptions, options);

    return this.each(function() {
      var select = $(this);
      select.select2(options);
      if (!options.width) select.data("select2").$container.css("width", "100%");
    });
  };
})(jQuery);
