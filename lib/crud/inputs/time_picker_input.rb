module Crud
  module Inputs
    class TimePickerInput < FlatpickrInput
      def default_options
        super.merge(noCalendar: true, enableTime: true, time_24hr: true)
      end
    end
  end
end
