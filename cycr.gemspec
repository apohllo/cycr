Gem::Specification.new do |s|
  s.name = "cycr"
  s.version = "0.0.1"
  s.date = "2008-12-26"
  s.summary = "Ruby client for the OpenCyc server"
  s.email = "apohllo@o2.pl"
  s.homepage = "http://www.opencyc.org"
  s.description = "Ruby wrapper for OpenCyc server and ontology"
  s.has_rdoc = false
  s.authors = ['Aleksander Pohl']
  s.files = ["Rakefile", 
    "cycr.gemspec", 
    'lib/cycr.rb', 
    'lib/cycr/collection.rb', 
    'lib/cycr/constants.rb', 
    'lib/cycr/sexpr.rex.rb', 
    'lib/cycr/client.rb',
    'lib/cycr/extensions.rb',
    'lib/cycr/nart.rb',
    'lib/cycr/words_reader.lisp',
    'lib/cycr/domains.lisp'
  ]  
  s.test_files = [
  ]
  s.rdoc_options = ["--main", "README.txt"]
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.txt"]
end

