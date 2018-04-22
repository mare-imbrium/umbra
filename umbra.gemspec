
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "umbra/version"

Gem::Specification.new do |spec|
  spec.name          = "ncumbra"
  spec.version       = Umbra::VERSION
  spec.authors       = ["kepler"]
  spec.email         = ["githubkepler.50s@gishpuppy.com"]

  spec.summary       = %q{tiny ncurses library for creating simple apps}
  spec.description   = %q{minimal, provides forms and a few basic widgets}
  spec.homepage      = "https://github.com/mare-imbrium/umbra"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_runtime_dependency "ffi-ncurses", ">= 0.4.0", ">= 0.4.0"
end
