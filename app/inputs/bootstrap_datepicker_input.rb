# coding: utf-8
class BootstrapDatepickerInput < BootstrapDatetimepickerInput
  def input(wrapper_options)
    hidden_input + date_picker + datepicker_js
  end
end
