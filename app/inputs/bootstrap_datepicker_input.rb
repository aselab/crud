# coding: utf-8
class BootstrapDatepickerInput < BootstrapDatetimepickerInput

  def date_picker(id, attribute_name, hidden, value)
    date = value && value.strftime("%Y-%m-%d")

    date_picker = <<-EOT
      <div class="input-prepend date">
        <span class="add-on"><i class="icon-calendar"></i></span>
        <input type="text" class="input-small" name="#{attribute_name.to_s + "_date_input"}" value="#{date}"/>
      </div>
      #{reset_button(id) unless @required}
      <div style="clear: none; padding-bottom: 20px;"></div>
    EOT

    js = <<-SCRIPT
      <script type="text/javascript">
        $(document).ready(function() {
          var hiddenInput = $("##{id}");
          var dateDiv = hiddenInput.next(".date");
          var dateInput = dateDiv.find("input");

          function datetimeSync() {
            hiddenInput.val(dateInput.val());
          }

          dateDiv.datepicker(#{datepicker_options.to_json}).change(datetimeSync);

          $("#clear-#{id}").click(function(){
            hiddenInput.val("");
            dateInput.val("");
            return false;
          });
        });
      </script>
    SCRIPT
    hidden + date_picker.html_safe + js.html_safe
  end

  def input
    id = input_html_options[:id] || object_name.gsub(/\[|\]\[/, "_").gsub(/\]/, "") + "_" + attribute_name.to_s
    hidden = @builder.hidden_field(attribute_name, input_html_options)
    value = @builder.object.send(attribute_name)
    date_picker(id, attribute_name, hidden, value)
  end
end
