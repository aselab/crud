# coding: utf-8
class BootstrapTimepickerInput < BootstrapDatetimepickerInput
  def input(wrapper_options)
    hidden_input + time_picker + timepicker_js
  end
end
