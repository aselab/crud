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
      <div class="input-prepend date">
        <span class="add-on"><i class="icon-calendar"></i></span>
        <input type="text" class="input-small" name="#{attribute_name.to_s + "_date_input"}" value="#{date}"/>
      </div>
    EOT

    time_picker = <<-EOT
      <div class="input-prepend">
        <span class="add-on prepend-left pull-left"><i class="icon-time"></i></span>
        <div class="bootstrap-timepicker">
          <input type="text" class="span1" name="#{attribute_name.to_s + "_datetime_input"}" value="#{time}"/>
        </div>
      </div>
      <span style="margin-left: 30px">#{reset_button(id) unless @required}</span>
    EOT

    js = javascript_tag(<<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{id}");
        var dateDiv = hiddenInput.next(".date");
        var dateInput = dateDiv.find("input");
        var timeInput = dateDiv.next(".input-prepend").find("input");

        function datetimeSync() {
          hiddenInput.val(dateInput.val() + " " + timeInput.val());
        }

        dateDiv.datepicker(#{datepicker_options.to_json}).change(datetimeSync);

        timeInput.timepicker(#{timepicker_options.to_json}).change(datetimeSync).parent().children("span").click(function(){
          if (timeInput.val() == "") {
            timeInput.val("00:00");
          }
        });

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
    hidden + date_picker.html_safe + time_picker.html_safe + js
  end
end
