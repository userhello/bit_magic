
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bit_magic/version"

Gem::Specification.new do |spec|
  spec.name          = "bit_magic"
  spec.version       = BitMagic::VERSION
  spec.authors       = ["Kia Kroas"]
  spec.email         = ["rubygems@userhello.net"]

  spec.summary       = %q{Bit field and bit flag utility library with integration for ActiveRecord and Mongoid}
  spec.description   = %q{This gem provides basic utility classes for reading and writing specific bits as flags or fields on Integer values. It lets you turn a single integer value into a collection of boolean values (flags) or smaller numbers (fields). Includes integration adapters for ActiveRecord and Mongoid with a simple interface to make your own custom adapter for any other ORM (ActiveModel, ActiveResource, etc).}
  spec.homepage      = "https://github.com/userhello/bit_magic"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "coco", "~> 0.15"
end
