# coding: utf-8
class BootstrapTimepickerInput < BootstrapDatetimepickerInput

  def time_picker(id, attribute_name, hidden, value)
    timezone = options[:timezone] || Rails.configuration.time_zone
    time = value && value.in_time_zone(timezone).strftime("%H:%M")

    time_picker = <<-EOT
      <div class="input-prepend input-group">
        <span class="add-on input-group-addon glyphicon glyphicon-time"></span>
        <input type="text" class="form-control" name="#{attribute_name.to_s + "_datetime_input"}" value="#{time}"/>
      </div>
      #{reset_button(id) unless @required}
    EOT

    js = javascript_tag(<<-SCRIPT
      $(document).ready(function() {
        var hiddenInput = $("##{id}");
        var timeInput = hiddenInput.next(".input-group").find("input");

        function datetimeSync() {
          hiddenInput.val(timeInput.val());
        }

        timeInput.timepicker(#{timepicker_options.to_json}).change(datetimeSync);

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
    id = input_html_options[:id] || object_name.to_s.gsub(/\[|\]\[/, "_").gsub(/\]/, "") + "_" + attribute_name.to_s
    hidden = @builder.hidden_field(attribute_name, input_html_options)
    value = @builder.object.send(attribute_name)
    time_picker(id, attribute_name, hidden, value)
  end
end
