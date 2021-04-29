# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name = 'natas'
  s.version = '0.1'
  s.licenses = ['MIT']
  s.summary = 'OverTheWire wargame Natas'
  s.authors = ['anim']
  s.email = 'me@telpart.ru'
  s.homepage = 'https://github.com/animotto/otw-natas'
  s.files = [
    'lib/shell.rb',
    'lib/console.rb',
    'lib/natas.rb'
  ]
  s.executables = ['natas']
  s.required_ruby_version = '>= 2.4'
end
