
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "where_row/version"

Gem::Specification.new do |spec|
  spec.name          = "where_row"
  spec.version       = WhereRow::VERSION
  spec.authors       = ["Odysseas Doumas"]
  spec.email         = ["odydoum@gmail.com"]

  spec.summary       = 'Write row value queries in active record'
  spec.description   = 'Write row value queries in active record'
  spec.homepage      = "https://github.com/odoumas/where_row"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.5.0"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activerecord", ">= 5.2", "< 7.1"

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "appraisal"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "yard"
end
