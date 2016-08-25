# coding: utf-8
class BootstrapDatetimepickerInput < SimpleForm::Inputs::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper
  include ActionView::Context

  def datepicker_options
    date_options = options[:datepicker_options] || {}
    date_options[:format] ||= "yyyy-mm-dd"
    date_options[:autoclose] ||= true
    date_options[:language] ||= "ja"
    date_options[:todayBtn] ||= true
    date_options[:todayHighlight] ||= true
    date_options
  end

  def timepicker_options
    time_options = options[:timepicker_options] || {}
    time_options[:disableFocus] ||= true
    time_options[:showSeconds] ||= false
    time_options[:showMeridian] ||= false
    time_options[:miniteStep] ||= 15
    time_options[:showInputs] ||= false
    time_options[:defaultTime] ||= "value"
    time_options
  end

  def date_picker
    s = <<-EOT
      <div class="input-group date" style="max-width: 224px;">
        <span class="input-group-addon"><span class="glyphicon glyphicon-calendar"></span></span>
        <input type="text" class="form-control" value="#{date}"/>
      </div>
    EOT
    s.html_safe
  end

  def time_picker
    s = <<-EOT
      <div class="input-group" style="max-width: 224px;">
        <span class="input-group-addon"><span class="glyphicon glyphicon-time"></span></span>
        <input type="text" class="form-control" value="#{time}"/>
      </div>
    EOT
    s.html_safe
  end

  def reset_button
    unless @required
      s = <<-EOT
        <i class="glyphicon glyphicon-remove" id="clear-#{input_id}" style="cursor: pointer; margin-left: 4px;"></i>
      EOT
      s.html_safe
    end
  end

  def datetimepicker_js
    javascript_tag <<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{input_id}");
        var dateDiv = hiddenInput.next().find(".date");
        var dateInput = dateDiv.find("input");
        var timeInput = dateDiv.parent().next(".form-group").find("input");
        function datetimeSync() {
          var timepicker = timeInput.data("timepicker");
          var hour = timepicker.hour < 10 ? '0' + timepicker.hour : timepicker.hour;
          var minute = timepicker.minute < 10 ? '0' + timepicker.minute : timepicker.minute;
          var second = timepicker.second < 10 ? '0' + timepicker.second : timepicker.second;
          var time = hour + ':' + minute + (timepicker.showSeconds ? ':' + second : '');
          hiddenInput.val(dateInput.val() + "T" + time);
        }
        function zindex(selector, index) {
          return function() { $(selector).css("z-index", index); };
        }

        dateDiv.datepicker(#{datepicker_options.to_json}).on("change", datetimeSync);
        timeInput.timepicker(#{timepicker_options.to_json}).on("change", datetimeSync);

        $("#clear-#{input_id}").click(function(){
          hiddenInput.val("");
          dateInput.val("");
          timeInput.val("");
          return false;
        });
      });
    SCRIPT
  end

  def datepicker_js
    javascript_tag <<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{input_id}");
        var dateDiv = hiddenInput.next().find(".date");
        var dateInput = dateDiv.find("input");

        function datetimeSync() {
          hiddenInput.val(dateInput.val());
        }

        dateDiv.datepicker(#{datepicker_options.to_json}).change(datetimeSync);

        $("#clear-#{input_id}").click(function(){
          hiddenInput.val("");
          dateInput.val("");
          return false;
        });
      });
    SCRIPT
  end

  def timepicker_js
    javascript_tag <<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{input_id}");
        var timeInput = hiddenInput.next().find("input");
        function datetimeSync() {
          hiddenInput.val(timeInput.val());
        }

        timeInput.timepicker(#{timepicker_options.to_json}).change(datetimeSync);

        $("#clear-#{input_id}").click(function(){
          hiddenInput.val("");
          timeInput.val("");
          return false;
        });
      });
    SCRIPT
  end

  def input_id
    input_html_options[:id] ||= "#{object_name.to_s.gsub(/\]\[|[^-a-zA-Z0-9:.]/, "_").sub(/_$/, "")}_#{attribute_name}"
  end

  def value
    v = input_options[:value] || input_options[:input_html].try("[]", :value) || @builder.object.send(attribute_name)
    v.respond_to?(:in_time_zone) ? v.in_time_zone(timezone) : v
  end

  def date
    value.try(:strftime, "%Y-%m-%d")
  end

  def time
    value.try(:strftime, "%H:%M")
  end

  def hidden_input
    @builder.hidden_field(attribute_name, input_html_options)
  end

  def timezone
    options[:timezone] || Rails.configuration.time_zone
  end

  def inline_elements(*elements)
    content_tag(:div, :class => "form-inline crud-form-inline") do
      elements.compact.map do |elem|
        content_tag(:div, elem, :class => "form-group crud-form-group", :style => "margin: 0px;")
      end.reduce(:+)
    end
  end

  def input(wrapper_options)
    hidden_input + inline_elements(date_picker, time_picker, reset_button) + datetimepicker_js
  end
end
