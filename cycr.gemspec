Gem::Specification.new do |s|
  s.name = "cycr"
  s.version = "0.0.2"
  s.date = "2009-05-27"
  s.summary = "Ruby client for the OpenCyc server"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.opencyc.org"
  s.description = "Ruby wrapper for OpenCyc server and ontology"
  s.has_rdoc = false
  s.authors = ['Aleksander Pohl']
  s.files = ["Rakefile", "cycr.gemspec", 'lib/cycr.rb'] +
    Dir.glob("lib/**/*")
  s.test_files = [
  ]
  s.rdoc_options = ["--main", "README.txt"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
end

