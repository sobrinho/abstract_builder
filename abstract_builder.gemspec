Gem::Specification.new do |spec|
  spec.name          = "abstract_builder"
  spec.version       = "0.1.0"
  spec.authors       = ["Gabriel Sobrinho"]
  spec.email         = ["gabriel.sobrinho@gmail.com"]

  spec.summary       = %q{AbstractBuilder gives you a simple DSL for declaring structures that beats manipulating giant hash structures.}
  spec.homepage      = "https://github.com/sobrinho/abstract_builder"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
