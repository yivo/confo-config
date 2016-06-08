# frozen_string_literal: true
# encoding: utf-8
require File.expand_path('../lib/confo/version', __FILE__)

Gem::Specification.new do |s|
  s.name            = 'confo-config'
  s.version         = Confo::VERSION
  s.authors         = ['Yaroslav Konoplov']
  s.email           = ['yaroslav@inbox.com']
  s.summary         = 'Little configuration framework'
  s.description     = 'Little configuration framework'
  s.homepage        = 'http://github.com/yivo/confo-config'
  s.license         = 'MIT'

  s.executables     = `git ls-files -z -- bin/*`.split("\x0").map{ |f| File.basename(f) }
  s.files           = `git ls-files -z`.split("\x0")
  s.test_files      = `git ls-files -z -- {test,spec,features}/*`.split("\x0")
  s.require_paths   = ['lib']

  s.add_dependency 'activesupport', '>= 3.2.0'
end
