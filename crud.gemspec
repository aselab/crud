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

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency "rails", "~> 3.2.13"
  s.add_dependency "jquery-rails"
  s.add_dependency "cancan"
  s.add_dependency "kaminari"
  s.add_dependency "simple_form"

  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "capybara"
  s.add_development_dependency "spork"

  s.add_development_dependency "therubyracer"
  s.add_development_dependency "less-rails"
  s.add_development_dependency "twitter-bootstrap-rails"

end
