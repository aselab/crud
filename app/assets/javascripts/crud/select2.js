(function($){
  // IEでtagモードのときfocusが外れるバグがあるのでoption追加削除検知を無効化
  if (document.uniqueID) {
    var Select2 = $.fn.select2.amd.require('select2/core');
    Select2.prototype._syncSubtree = function() {}
  }

  // https://github.com/select2/select2/issues/3320
  $.fn.select2UnselectFix = function() {
    return this.each(function() {
      var elem = $(this).on('select2:unselecting', function(e) {
        elem.data('unselecting', true);
      }).on('select2:open', function(e) {
        if (elem.data('unselecting')) {
          elem.removeData('unselecting');
          elem.select2('close');
        }
      });
    });
  };

  $.fn.crudSelect2 = function(options) {
    if (!options) options = {};
    var defaultOptions = {
      searchKey: "term",
      labelMethod: "name",
      idMethod: "id",
      language: "ja",
      allowClear: !options.multiple
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
           if (params.term) {
             data[options.searchKey] = params.term;
             data = $.extend(true, data, options.searchParams);
           }
          return data;
        },
        processResults: function(d, params) {
          $(d.items).each(function() {
            this.id = this[options.idMethod];
            this.text = this[options.labelMethod];
          });
          var currentPage = params.page || 1;
          return {results: d.items, pagination: {more: currentPage < d.meta.total_pages}};
        }
      };
    }
    options = $.extend(true, defaultOptions, options);

    return this.each(function() {
      var select = $(this);
      // bodyに追加するとmodalのフォーカスと衝突するのを回避
      var opts = $.extend({dropdownParent: select.parent()}, options);
      select.select2(opts).select2UnselectFix();
      if (!options.width) select.data("select2").$container.css("width", "100%");
    });
  };
})(jQuery);
