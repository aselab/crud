# coding: utf-8
class BootstrapDatepickerInput < SimpleForm::Inputs::Base
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::JavaScriptHelper

  def self.date_picker(id, attribute_name, hidden, value)
    date = value && value.strftime("%Y-%m-%d")

    date_picker = <<-EOT
      <div class="input-append date" data-date-format="yyyy-mm-dd" style="margin-right: 5px; float:left;">
        <input type="text" class="input-small" name="#{attribute_name.to_s + "_date_input"}" readonly="true" value="#{date}">
        <span class="add-on">
          <i class="icon-calendar"></i>
        </span>
      </div>
      <i class="icon-remove" id="clear-#{id}" style="cursor: pointer"></i>
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

          dateDiv.datepicker({
            format: "yyyy-mm-dd",
            autoclose: true,
            language: "ja"
          }).change(datetimeSync);

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
    id = input_html_options[:id] || object_name + "_" + attribute_name.to_s
    hidden = @builder.hidden_field(attribute_name, input_html_options)
    value = @builder.object.send(attribute_name)
    BootstrapDatepickerInput.date_picker(id, attribute_name, hidden, value)
  end
end
