import jQuery from 'jquery'

(function($){
  var methods = {
    init: function(options) {
      if (!options) options = {};
      var defaultOptions = {
        labelMethod: "label",
        valueMethod: "id",
        icon: '<i class="fas fa-th-list"></i>',
        selectedItem: []
      };
      options = $.extend(true, defaultOptions, options);

      var labelMethod = options.labelMethod;
      var valueMethod = options.valueMethod;
      var multiple = options.multiple;

      function label(data) {
        var elem = $("<span/>").addClass("picker-label").text(data[labelMethod]);
        if (multiple) elem.addClass("multiple");
        return elem;
      }

      var template = $("<div/>").addClass("modal-picker").append(
        $("<div/>").addClass("input-group").append(
          $("<div/>").addClass("input-group-prepend").append(
            $("<div/>").addClass("input-group-text").append(options.icon)
          ),
          $("<div/>").addClass("form-control").append(
            $("<span/>").addClass("picker-container").append(
              $("<span/>").addClass("picker-clear").html("&times; "),
              $("<span/>").addClass("picker-placeholder").text(options.placeholder),
              $("<span/>").addClass("picker-value")
            )
          )
        )
      );

      return this.each(function() {
        var input = $(this).data({ label_method: labelMethod, value_method: valueMethod }).after(template.clone());
        input.data("modalPicker", $.extend(true, {}, options));
        var canModalOpen = true;

        function createMultipleOptions(selectedValue) {
          var name = input.attr("name");
          var select = $("<select/>").attr({name: name, multiple: "true"}).css("display", "none");
          input.next("select").remove();
          $.each(selectedValue, function(i, e) {
            var option = $("<option/>").attr({value: e[valueMethod], selected: "selected"});
            select.append(option);
          });
          input.after(select);
        }

        function setPickerValue(selectedValue) {
          if ($.isArray(selectedValue)) {
            var placeholder = input.parent().find(".picker-placeholder");
            var clear = input.parent().find(".picker-clear");
            var labels = $.map(selectedValue, function(e) { return label(e) });
            input.parent().find(".picker-value").html(labels);
            if (selectedValue.length == 0) {
              placeholder.show();
              clear.hide();
            } else {
              placeholder.hide();
              clear.show();
            }

            if (multiple) {
              createMultipleOptions(selectedValue);
            } else {
              input.val(selectedValue[0] ? selectedValue[0][valueMethod] : "");
            }

            if ($.isFunction(options.onChangeHint)) {
              options.onChangeHint(selectedValue);
            } else if (options.onChangeHint) {
              onChangeHintScript(options.onChangeHint, selectedValue);
            }
          }
        }

        function onChangeHintScript(script, selectedValue) {
          var callback = Function("$data", "return " + script);
          var hint = input.siblings("small.text-muted");
          var newHintHtml = $.map(selectedValue, function(data) {
            return $("<span/>").html(callback(data)).attr({"data-id": data[valueMethod], "class": "chnage_hint_effect"}).get(0).outerHTML;
          }).join("");
          if (hint.length) {
            if (newHintHtml != "") { hint.html(newHintHtml); }
          } else {
            var newHint = $("<small/>").attr("class", "form-text text-muted").html(newHintHtml);
            newHint.appendTo(input.parent());
          }
        }

        function onClear(e) {
          e.stopPropagation();
          input.data("selected", []);
          input.trigger("change");
        }

        input.parent().find("span.picker-clear").click(onClear);

        input.on("clear", onClear);

        input.next(".modal-picker").click(function() {
          if (!canModalOpen) {
            return false;
          }
          canModalOpen = false;
          var params = $.param({
            modal_target: input.attr("id"),
            multiple: multiple
          });
          var url = input.data("modalPicker").url;
          if (!url) throw new Error("url not defined");
          url += url.indexOf("?") >= 0 ? "&" : "?"
          $.getScript(url + params, function() { canModalOpen = true; });
        });

        input.on("change", function(e) {
          var selectedValue = $(this).data("selected");
          setPickerValue(selectedValue);
          if (multiple) selectedValue = [selectedValue];
          $(this).trigger("picker-changed", selectedValue);
          e.stopPropagation();
        });

        var selected = options.selectedItem || [];
        if (!Array.isArray(selected)) selected = [selected];
        input.val("").data("selected", selected);
        setPickerValue(input.data("selected"));

        $(this).data("setPickerValue", setPickerValue);
      });
    },
    url: function(value) {
      return this.each(function() {
        $(this).data("modalPicker").url = value;
      });
    },
    setPickerValue: function(value) {
      return this.each(function() {
        var setPickerValue = $(this).data("setPickerValue");
        setPickerValue(value);
      });
    }
  };

  $.fn.modalPicker = function(method) {
    if ( methods[method] ) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'object' || !method) {
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' +  method + ' does not exist on jQuery.modalPicker');
    }
  };
})(jQuery);
