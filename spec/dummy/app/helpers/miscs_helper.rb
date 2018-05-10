module MiscsHelper
  def miscs_file_input_options
    { as: :bootstrap_filestyle }
  end

  def miscs_misc_belongings_input_options
    { as: :select2 }
  end

  def miscs_misc_habtms_input_options
    url = resource.is_a?(ActiveRecord::Base) ? pickers_ar_misc_habtms_path : pickers_mongo_misc_habtms_path
    { as: :modal_picker, url: url }
  end
end
