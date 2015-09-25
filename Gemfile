source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false

  gem 'metadata-json-lint'
  gem 'puppet-lint-absolute_classname-check'
  gem 'puppet-lint-absolute_template_path'
  gem 'puppet-lint-trailing_newline-check'

  gem 'puppet-lint-unquoted_string-check'
  gem 'puppet-lint-leading_zero-check'
  gem 'puppet-lint-variable_contains_upcase'
  gem 'puppet-lint-spaceship_operator_without_tag-check'
  gem 'puppet-lint-undef_in_function-check'

  if puppetversion = ENV['PUPPET_GEM_VERSION']
    gem 'puppet', puppetversion, :require => false
  else
    gem 'puppet', '~> 3.0', :require => false
  end
end

group :system_tests do
  gem 'beaker-rspec', :require => false
end

# vim:ft=ruby
