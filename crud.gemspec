$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "crud/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "crud"
  s.version     = Crud::VERSION
  s.authors     = ["Akihiro Ono"]
  s.email       = ["akihiro@ase.co.jp"]
  s.homepage    = ""
  s.summary     = "CRUD controller for Rails"
  s.description = "This plugin provides base controller that supports authorization and search, sort, pagination."

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "crud_api"
  s.add_dependency "jquery-rails"
  s.add_dependency "bootstrap-sass"
  s.add_dependency "font-awesome-sass"

  s.add_dependency "simple_form", "~> 3.2.1"
  s.add_dependency "select2-rails", "4.0.3"

  s.add_development_dependency "sass-rails", "~> 5.0.5"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mongoid", '~> 6.0.0.rc0'
  s.add_development_dependency "kaminari-mongoid"
  s.add_development_dependency "cocoon"
  s.add_development_dependency "enumerize"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara"
  s.add_development_dependency "spring"
  s.add_development_dependency "spring-commands-rspec"
  s.add_development_dependency "pry-rails"
end
