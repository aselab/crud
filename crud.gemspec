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
  s.add_dependency "simple_form", "~> 4.0.0"

  s.add_development_dependency "webpacker", '~> 3.4.3'
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "mongoid", '~> 7.0.0'
  s.add_development_dependency "kaminari-mongoid"
  s.add_development_dependency "cocoon"
  s.add_development_dependency "enumerize"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "factory_bot_rails"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "capybara"
  s.add_development_dependency "spring"
  s.add_development_dependency "spring-commands-rspec"
  s.add_development_dependency "pry-rails"
  s.add_development_dependency "listen"
end
