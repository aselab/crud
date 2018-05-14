require 'crud/simple_form/initializers/simple_form'
require 'crud/simple_form/initializers/simple_form_bootstrap'

SimpleForm.setup do |config|
  config.custom_inputs_namespaces << "Crud::Inputs"
end

module SimpleForm
  class Inputs::Base
    def valid?
      Crud.config.simple_form.use_valid_class && super
    end
  end

  class FormBuilder
    map_type :file, to: Crud::Inputs::BootstrapFilestyleInput
    map_type :datetime, to: Crud::Inputs::DatetimePickerInput
    map_type :date, to: Crud::Inputs::DatePickerInput
    map_type :time, to: Crud::Inputs::TimePickerInput
  end
end
