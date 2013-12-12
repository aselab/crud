# coding: utf-8
class BootstrapDatetimepickerInput < SimpleForm::Inputs::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

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

  def reset_button(id)
    <<-EOT
      <i class="icon-remove" id="clear-#{id}" style="cursor: pointer"></i>
    EOT
  end

  def input
    id = input_html_options[:id] || object_name.to_s.gsub(/\[|\]\[/, "_").gsub(/\]/, "") + "_" + attribute_name.to_s
    hidden = @builder.hidden_field(attribute_name, input_html_options)
    value = @builder.object.send(attribute_name).try(:utc)
    timezone = options[:timezone] || Rails.configuration.time_zone
    date = value && value.in_time_zone(timezone).strftime("%Y-%m-%d")
    time = value && value.in_time_zone(timezone).strftime("%H:%M")

    date_picker = <<-EOT
      <div class="input-group date col-xs-6">
        <span class="input-group-addon add-on"><i class="icon-calendar"></i></span>
        <input type="text" class="form-control" name="#{attribute_name.to_s + "_date_input"}" value="#{date}"/>
      </div>
    EOT

    time_picker = <<-EOT
      <div class="input-prepend input-group col-xs-4">
        <span class="input-group-addon"><i class="icon-time"></i></span>
        <input type="text" class="form-control" name="#{attribute_name.to_s + "_datetime_input"}" value="#{time}"/>
      </div>
      #{reset_button(id) unless @required}
    EOT

    js = javascript_tag(<<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{id}");
        var dateDiv = hiddenInput.next().find(".date");
        var dateInput = dateDiv.find("input");
        var timeInput = dateDiv.next(".input-group").find("input");
        function datetimeSync() {
          var timepicker = timeInput.data("timepicker");
          var hour = timepicker.hour < 10 ? '0' + timepicker.hour : timepicker.hour;
          var minute = timepicker.minute < 10 ? '0' + timepicker.minute : timepicker.minute;
          var second = timepicker.second < 10 ? '0' + timepicker.second : timepicker.second;
          var time = hour + ':' + minute + (timepicker.showSeconds ? ':' + second : '');
          hiddenInput.val(dateInput.val() + "T" + time);
        }

        dateDiv.datepicker(#{datepicker_options.to_json}).change(datetimeSync);

        timeInput.timepicker(#{timepicker_options.to_json}).change(datetimeSync);

        $("#clear-#{id}").click(function(){
          hiddenInput.val("");
          dateInput.val("");
          timeInput.val("");
          return false;
        });

        if ("#{time}" == "") {
          timeInput.val("");
        }
      });
      SCRIPT
    )
    hidden + content_tag(:div, (date_picker + time_picker).html_safe, :class => "row") + js
  end
end
