import jQuery from 'jquery'
import select2 from 'select2'
import 'select2/dist/css/select2.css'
import 'select2-bootstrap4-theme/dist/select2-bootstrap4.css'

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

    $.fn.select2OnChangeHintEffect = function() {
      return this.each(function() {
        $(this).on("select2:select", function(e) {
          var data = e.params.data;
          var callback = Function("$data", "return " + options.onChangeHint);
          var newHintHtml = $("<span/>").html(callback(data)).attr({"data-id": data.id, "class": "chnage_hint_effect"});
          var target = $(e.target);
          var hint = target.siblings("small.text-muted");
          if (hint.length) {
            if (hint.text() == options.hint) {
              hint.html(newHintHtml);
            } else {
              hint.append(newHintHtml);
            }
          } else {
            var newHint = $("<small/>").attr("class", "form-text text-muted").html(newHintHtml);
            newHint.appendTo(target.parent());
          }
        }).on("select2:unselect", function(e) {
          var target = $(e.target);
          if ($.inArray(e.params.data.id.toString(), target.val()) == -1) {
            var hint = target.siblings("small.text-muted").find("span[data-id='" + e.params.data.id + "']");
            hint.remove();
          }
        }).on("change", function (e) {
          var target = $(e.target);
          if ($.isEmptyObject(target.val())) {
            target.siblings("small.text-muted").text(options.hint || "");
          }
        });
      });
    };

    return this.each(function() {
      var select = $(this);
      // bodyに追加するとmodalのフォーカスと衝突するのを回避
      var opts = $.extend({dropdownParent: select.parent()}, options);
      select.select2(opts).select2UnselectFix();

      if (options.onChangeHint) select.select2OnChangeHintEffect();

      if (!options.width) select.data("select2").$container.css("width", "100%");
    });
  };
})(jQuery);
