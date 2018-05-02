$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "crud/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "crud_api"
  s.version     = Crud::VERSION
  s.authors     = ["Akihiro Ono"]
  s.email       = ["akihiro@ase.co.jp"]
  s.homepage    = ""
  s.summary     = "CRUD API controller for Rails"
  s.description = "This plugin provides base controller that supports authorization and search, sort, pagination."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", ">= 5.2.0"
  s.add_dependency "kaminari"
  s.add_dependency "active_model_serializers", "~> 0.10.7"
  s.add_dependency "memoist"
end
