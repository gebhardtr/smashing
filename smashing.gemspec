# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name        = 'smashing'

  s.version     = '1.3.5.pre'
  s.date        = '2021-03-06'
  s.executables = %w(smashing)


  s.summary     = "The wonderfully excellent dashboard framework."
  s.description = "A framework for pulling together an overview of data that is important to your team and displaying it easily on TVs around the office. You write a bit of ruby code to gather data from some services and let Smashing handle the rest - displaying that data in a wonderfully simple layout. Built for developers and hackers, Smashing is highly customizable while maintaining humble roots that make it approachable to beginners."
  s.author      = "Daniel Beauchamp"
  s.homepage    = 'http://smashing.github.io/smashing'
  s.license     = "MIT"

  s.metadata = {
    "bug_tracker_uri"   => "https://github.com/Smashing/smashing/issues",
    # "changelog_uri"     => "https://github.com/Smashing/smashing/CHANGELOG.md",
    "documentation_uri" => "https://github.com/Smashing/smashing/wiki",
    "homepage_uri"      => "https://smashing.github.io/",
    "mailing_list_uri"  => "https://gitter.im/Smashing/Lobby",
    "source_code_uri"   => "https://github.com/Smashing/smashing/",
    "wiki_uri"          => "https://github.com/Smashing/smashing/wiki"
  }

  s.files = Dir['README.md', 'javascripts/**/*', 'templates/**/*','templates/**/.[a-z]*', 'lib/**/*']

  s.add_dependency('coffee-script', '~> 2.4')
  s.add_dependency('execjs', '~> 2.7')
  if RUBY_VERSION < "2.4.0"
    s.add_dependency('sinatra', '= 2.0.4') 
  else
    s.add_dependency('sinatra', '~> 2.0')
  end
  s.add_dependency('sinatra-contrib', '~> 2.0')
  s.add_dependency('thin', '~> 1.7')
  s.add_dependency('rufus-scheduler', '~> 3.6')
  s.add_dependency('thor', '~> 1.0')
  if RUBY_VERSION < "2.5.0"
    s.add_dependency('sprockets', '~> 3.7')
    s.add_dependency('sass', '~> 3.4')
  else
    s.add_dependency('sprockets', '~> 4.0')
    s.add_dependency('sassc', '~> 2.0')
  end
  s.add_dependency('rack', '~> 2.2')

  s.add_development_dependency('rake', '~> 12.3.3')
  s.add_development_dependency('haml', '~> 5.0.1')
  s.add_development_dependency('rack-test', '~> 0.6.3')
  s.add_development_dependency('minitest', '~> 5.10.2')
  s.add_development_dependency('mocha', '~> 1.2.1')
  s.add_development_dependency('fakeweb', '~> 1.3.0')
  s.add_development_dependency('simplecov', '~> 0.14.1')
end
