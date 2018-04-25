# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../../Gemfile', __dir__)

if File.exist?(ENV['BUNDLE_GEMFILE'])
  require 'bundler/setup'
  require 'bootsnap/setup'
end
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
