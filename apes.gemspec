#
# This file is part of the apes gem. Copyright (C) 2016 and above Shogun <shogun@cowtech.it>.
# Licensed under the MIT license, which can be found at http://www.opensource.org/licenses/mit-license.php.
#

require File.expand_path("../lib/apes/version", __FILE__)

Gem::Specification.new do |gem|
  gem.name = "apes"
  gem.version = Apes::Version::STRING
  gem.homepage = "https://github.com/ShogunPanda/apes"
  gem.summary = %q{A tiny JSON API framework for Ruby on Rails.}
  gem.description = %q{A tiny JSON API framework for Ruby on Rails.}
  gem.rubyforge_project = "apes"

  gem.authors = ["Shogun"]
  gem.email = ["shogun@cowtech.it"]
  gem.license = "MIT"

  gem.files = `git ls-files`.split($\)
  gem.executables = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.required_ruby_version = ">= 2.3.0"

  # Add gem dependencies here
  gem.add_dependency("lazier", "~> 4.2.1")
  gem.add_dependency("mustache", "~> 1.0.3")
  gem.add_dependency("jwt", "~> 1.5.4")
  gem.add_dependency("rails", "~> 4.2")
  gem.add_dependency("rails-api", "~> 0.4")
end
