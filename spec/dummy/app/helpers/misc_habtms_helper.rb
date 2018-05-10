module MiscHabtmsHelper
  def misc_habtms_miscs_input_options
    url = resource.is_a?(ActiveRecord::Base) ? pickers_ar_miscs_path : pickers_mongo_miscs_path
    { as: :modal_picker, url: url }
  end
end
