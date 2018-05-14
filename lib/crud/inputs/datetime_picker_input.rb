module Crud
  module Inputs
    class DatetimePickerInput < FlatpickrInput
      def default_options
        super.merge(enableTime: true, time_24hr: true)
      end
    end
  end
end
