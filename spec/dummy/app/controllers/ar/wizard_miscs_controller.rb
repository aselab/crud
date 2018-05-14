class Ar::WizardMiscsController < Ar::MiscsController
  include Crud::Wizard

  steps :one, :two, :three

  protected
  def model
    Ar::Misc
  end

  def cancel_path
    ar_miscs_path
  end
end
