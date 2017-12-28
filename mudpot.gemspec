$:.push File.expand_path("../lib", __FILE__)
require 'mudpot/version'

Gem::Specification.new do |s|
  s.name        = 'mudpot'
  s.version     = Mudpot::VERSION
  s.summary     = 'summary'
  s.authors     = ['Aligo Kang']
  
  s.files         = Dir['./**/*'].reject { |file| file =~ /\.\/(bin|log|pkg|script|s|test|vendor|tmp)/ }
  s.test_files    = `git ls-files -- {test,s,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']

  s.add_runtime_dependency     'whittle', '~> 0'
  s.add_development_dependency 'rspec', '~> 0'
end