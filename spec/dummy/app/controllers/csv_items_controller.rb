class CsvItemsController < Crud::ApplicationController
  permit_keys :string, :integer, :boolean, :date, :datetime
end
