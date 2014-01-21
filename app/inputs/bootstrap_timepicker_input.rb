# coding: utf-8
class BootstrapTimepickerInput < BootstrapDatetimepickerInput
  def input
    hidden_input + inline_elements(time_picker, reset_button) + timepicker_js
  end
end
