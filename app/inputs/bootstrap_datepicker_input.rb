# coding: utf-8
class BootstrapDatepickerInput < BootstrapDatetimepickerInput
  def input(wrapper_options)
    hidden_input + inline_elements(date_picker, reset_button) + datepicker_js
  end
end
