# coding: utf-8
class BootstrapDatepickerInput < BootstrapDatetimepickerInput
  def input
    hidden_input + inline_elements(date_picker, reset_button) + datepicker_js
  end
end
