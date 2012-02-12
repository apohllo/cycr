task :default => [:test]

$gem_name = "cycr"

desc "Run tests"
task :test do
  puts "WARNING: The test have to be run with an available Cyc server"
  sh "rspec spec/assertion.rb"
  sh "rspec spec/client.rb"
  sh "rspec spec/parser.rb"
end

desc "Build the gem"
task :build do
  sh "gem build #$gem_name.gemspec"
end

desc "Install the library at local machnie"
task :install => :build do 
  sh "sudo gem install #$gem_name -l"
end

desc "Uninstall the library from local machnie"
task :uninstall do
  sh "sudo gem uninstall #$gem_name"
end

desc "Clean"
task :clean do
  sh "rm #$gem_name*.gem" 
end
