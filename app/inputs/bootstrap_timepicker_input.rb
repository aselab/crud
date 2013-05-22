# coding: utf-8
class BootstrapTimepickerInput < BootstrapDatetimepickerInput

  def time_picker(id, attribute_name, hidden, value)
    time = value && value.strftime("%H:%M")

    time_picker = <<-EOT
      <div class="input-prepend">
        <span class="add-on prepend-left pull-left"><i class="icon-time"></i></span>
        <div class="bootstrap-timepicker">
          <input type="text" class="span1" name="#{attribute_name.to_s + "_datetime_input"}" value="#{time}"/>
        </div>
      </div>
      <span style="margin-left: 30px">#{reset_button(id) unless @required}</span>
      <div style="clear: none; padding-bottom: 20px;"></div>
    EOT

    js = javascript_tag(<<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{id}");
        var timeInput = hiddenInput.next(".input-prepend").find("input");

        function datetimeSync() {
          hiddenInput.val(timeInput.val());
        }

        timeInput.timepicker(#{timepicker_options.to_json}).change(datetimeSync).parent().children("span").click(function(){
          if (timeInput.val() == "") {
            timeInput.val("00:00");
          }
        });

        $("#clear-#{id}").click(function(){
          hiddenInput.val("");
          timeInput.val("");
          return false;
        });

        if ("#{time}" == "") {
          timeInput.val("");
        }
      });
      SCRIPT
    )
    hidden + time_picker.html_safe + js
  end

  def input
    id = input_html_options[:id] || object_name.gsub(/\[|\]\[/, "_").gsub(/\]/, "") + "_" + attribute_name.to_s
    hidden = @builder.hidden_field(attribute_name, input_html_options)
    value = @builder.object.send(attribute_name)
    time_picker(id, attribute_name, hidden, value)
  end
end
