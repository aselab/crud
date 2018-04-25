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
    date_options[:class] ||= ""
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
    time_options[:class] ||= ""
    time_options
  end

  def date_picker(style = nil)
    s = <<-EOT
      <div class="input-prepend input-group date #{datepicker_options[:class]}" style="#{style};">
        <span class="input-group-addon"><span class="fa fa-calendar"></span></span>
        #{reset_button}
        <input type="text" class="form-control" value="#{date}"/>
      </div>
    EOT
    s.html_safe
  end

  def time_picker(style = nil)
    s = <<-EOT
      <div class="input-prepend input-group time #{timepicker_options[:class]}" style="#{style};">
        <span class="input-group-addon"><span class="fa fa-clock-o"></span></span>
        #{reset_button}
        <input type="text" class="form-control" value="#{time}"/>
      </div>
    EOT
    s.html_safe
  end

  def reset_button
    content_tag(:i, nil, class: "fa fa-close date-clear") unless @required
  end

  def datetimepicker_js
    javascript_tag <<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{input_id}");
        var container = hiddenInput.parent();
        var dateDiv = container.find(".date");
        var dateInput = dateDiv.find("input");
        var dateClear = dateDiv.find(".date-clear");
        var timeDiv = container.find(".time");
        var timeInput = timeDiv.find("input");
        var timeClear = timeDiv.find(".date-clear");
        function updateClearButton() {
          dateInput.val() ? dateClear.show() : dateClear.hide();
          timeInput.val() ? timeClear.show() : timeClear.hide();
        }

        function datetimeSync() {
          var timepicker = timeInput.data("timepicker");
          var hour = timepicker.hour < 10 ? '0' + timepicker.hour : timepicker.hour;
          var minute = timepicker.minute < 10 ? '0' + timepicker.minute : timepicker.minute;
          var second = timepicker.second < 10 ? '0' + timepicker.second : timepicker.second;
          var time = hour + ':' + minute + (timepicker.showSeconds ? ':' + second : '');
          if(dateInput.val() && timeInput.val()){
            hiddenInput.val(dateInput.val() + "T" + time);
          }else{
            hiddenInput.val("");
          }
          updateClearButton();
          hiddenInput.trigger("change");
        }

        function clear() {
          hiddenInput.val("");
          dateInput.val("");
          timeInput.val("");
          updateClearButton();
          hiddenInput.trigger("change");
        }

        dateDiv.datepicker(#{datepicker_options.to_json}).on("change", datetimeSync);
        timeInput.timepicker(#{timepicker_options.to_json}).on("change", datetimeSync);
        updateClearButton();

        dateClear.on("click", clear);
        timeClear.on("click", clear);

        #{"clear()" if date.nil? && time.nil? }
      });
    SCRIPT
  end

  def datepicker_js
    javascript_tag <<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{input_id}");
        var container = hiddenInput.parent();
        var dateDiv = container.find(".date");
        var dateInput = dateDiv.find("input");
        var dateClear = dateDiv.find(".date-clear");
        function updateClearButton() {
          dateInput.val() ? dateClear.show() : dateClear.hide();
        }

        function datetimeSync() {
          hiddenInput.val(dateInput.val());
          updateClearButton();
          hiddenInput.trigger("change");
        }

        dateDiv.datepicker(#{datepicker_options.to_json}).change(datetimeSync);
        updateClearButton();

        dateClear.on("click", function(){
          hiddenInput.val("");
          dateInput.val("");
          updateClearButton();
          hiddenInput.trigger("change");
        });
      });
    SCRIPT
  end

  def timepicker_js
    javascript_tag <<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{input_id}");
        var container = hiddenInput.parent();
        var timeDiv = container.find(".time");
        var timeInput = timeDiv.find("input");
        var timeClear = timeDiv.find(".date-clear");
        function updateClearButton() {
          timeInput.val() ? timeClear.show() : timeClear.hide();
        }
        function datetimeSync() {
          hiddenInput.val(timeInput.val());
          updateClearButton();
          hiddenInput.trigger("change");
        }

        timeInput.timepicker(#{timepicker_options.to_json}).change(datetimeSync);
        updateClearButton();

        container.on("click", ".date-clear", function(){
          hiddenInput.val("");
          timeInput.val("");
          updateClearButton();
          hiddenInput.trigger("change");
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
    content_tag(:span, elements.map(&:strip).join("").html_safe, :class => "crud-form-inline row")
  end

  def input(wrapper_options)
    hidden_input + inline_elements(date_picker(), time_picker()) + datetimepicker_js
  end
end
