$:.unshift "lib"
require 'cyc/version'

Gem::Specification.new do |s|
  s.name = "cycr"
  s.version = Cyc::VERSION.to_s
  s.required_ruby_version = '>= 1.9.2'
  s.date = "#{Time.now.strftime("%Y-%m-%d")}"
  s.summary = "Ruby client for the (Open)Cyc server"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://github.com/apohllo/cycr"
  s.require_path = "lib"
  s.description = "Ruby wrapper for (Open)Cyc server and ontology"
  s.authors = ['Aleksander Pohl', 'Rafal Michalski']
  s.files = `git ls-files`.split("\n")
  s.test_files = Dir.glob("spec/**/*") + Dir.glob("integration/**/*")
  s.rdoc_options = ["--main", "README.rdoc"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.add_development_dependency("rspec", ["~> 2.8.0"])
  s.add_development_dependency("em-synchrony", ["~> 1.0.0"])
  s.add_dependency("ref", ["~> 1.0.0"])
end
