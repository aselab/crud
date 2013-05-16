# coding: utf-8
class BootstrapDatetimepickerInput < SimpleForm::Inputs::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  def input
    id = input_html_options[:id] || object_name + "_" + attribute_name.to_s
    hidden = @builder.hidden_field(attribute_name, input_html_options)
    value = @builder.object.send(attribute_name)
    date = value && value.strftime("%Y-%m-%d")
    time = value && value.strftime("%H:%M")

    date_picker = <<-EOT
      <div class="input-append date" data-date-format="yyyy-mm-dd" style="margin-right: 5px; float: left;">
        <input type="text" class="input-small" name="#{attribute_name.to_s + "_date_input"}" readonly="true" value="#{date}">
        <span class="add-on">
          <i class="icon-calendar"></i>
        </span>
      </div>
    EOT

    time_picker = <<-EOT
      <div class="input-append bootstrap-timepicker-component" style="margin-right: 5px; float: left;">
        <input type="text" class="input-small" name="#{attribute_name.to_s + "_datetime_input"}" readonly="true" value="#{time}">
        <span class="add-on">
          <i class="icon-time"></i>
        </span>
      </div>
      <i class="icon-remove" id="clear-#{id}" style="cursor: pointer"></i>
      <div style="clear: none; padding-bottom: 20px;"></div>
    EOT

    js = javascript_tag(<<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{id}");
        var dateDiv = hiddenInput.next(".date");
        var dateInput = dateDiv.find("input");
        var timeInput = hiddenInput.nextAll(".bootstrap-timepicker-component").children("input");

        function datetimeSync() {
          hiddenInput.val(dateInput.val() + " " + timeInput.val());
        }

        dateDiv.datepicker({
          format: "yyyy-mm-dd",
          autoclose: true,
          language: "ja"
        }).change(datetimeSync);

        timeInput.timepicker({
          showSeconds: false,
          showMeridian: false,
          miniteStep: 15,
          defaultTime: "value"
        }).change(datetimeSync).parent().children("span").click(function(){
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
