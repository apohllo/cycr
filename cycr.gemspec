Gem::Specification.new do |s|
  s.name = "cycr"
  s.version = "0.0.3"
  s.date = "2010-10-19"
  s.summary = "Ruby client for the (Open)Cyc server"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.opencyc.org"
  s.require_path = "lib"
  s.description = "Ruby wrapper for (Open)Cyc server and ontology"
  s.has_rdoc = false
  s.authors = ['Aleksander Pohl']
  s.files = ["Rakefile", "cycr.gemspec", 'lib/cycr.rb'] +
    Dir.glob("lib/**/*")
  s.test_files = Dir.glob("spec/**/*")
  s.rdoc_options = ["--main", "README.txt"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
  s.add_dependency("rspec", [">= 1.2.9"])
end

