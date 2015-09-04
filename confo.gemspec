require File.expand_path('../lib/confo/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'confo-config'
  spec.version       = Confo::VERSION
  spec.authors       = ['Yaroslav Konoplov']
  spec.email         = ['yaroslav@inbox.com']
  spec.summary       = 'Little configuration framework'
  spec.description   = 'Little configuration framework'
  spec.homepage      = 'http://github.com/yivo/confo-config'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '~> 4.0' # 4.0 <= version < 5.0
end
