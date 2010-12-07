= cycr

* http://github.com/apohllo/cycr

= DESCRIPTION

'cycr' is a Ruby client for the (Open)Cyc server http://www.opencyc.org.

= FEATURES/PROBLEMS

* The text protocol is used to talk with Cyc
* Ruby symbols are converted to Cyc symbols
* Ruby arrays are converted to SubL arrays
* Ruby calls on the client are transparently translated to SubL
* Support for subcalls (like 'with-any-mt')
* Support for NARTs might not be fully functional (but works somehow)
* Support for CycL queries not implemented yet!

= SYNOPSIS

'cycr' is a Ruby client for the (Open)Cyc server. It is designed as a
substitution for the original Java client. It allows for conversation
with the ontology with regular Ruby objects (like symbols, arrays) 
and also exposes the raw text protocol.

= REQUIREMENTS

(Open)Cyc server with TCP communication enabled.

= INSTALL

You need RubyGems v.1.3.5 at least:

  $ gem -v
  1.2.0 # => not OK
  $ gem update --system
  ...
  $ gem -v 
  1.3.7 # => OK

The gem is available at rubygems.org, so you can install it with:

  $ sudo gem install cycr

== BASIC USAGE

Prerequisites:

* Cyc server is running 
** you can download it from http://www.opencyc.org
* Telnet connection is on
** type (enable-tcp-server :cyc-api 3601) in the cyc console or Cyc Browser
   -> Tools -> Interactor

The you can start 'irb' to see it in action:

  $ irb
  # include the cycr gem
  require 'cycr'

  # create the cyc client object, default host: localhost, port: 3601
  cyc = Cyc::Client.new

  # check if Dog generalizes to Animal
  cyc.genls? :Dog, :Animal # => T

  # check if Animal generalizes to Dog
  cyc.genls? :Animal, :Dog # => nil

  # check the minimal generalizations of Animal
  genls = cyc.min_genls :Animal
  # => [:"Organism-Whole", :"PerceptualAgent-Embodied",
    :"Agent-NonArtifactual", :SolidTangibleThing, [:CollectionUnionFn,
    [:TheSet, :Animal, [:GroupFn, :Animal]]],...

  # check the maximal specializations of the first of the above results
  cyc.max_specs genls.first
  # => [:Microorganism, :EukaryoticOrganism, :"Unvaccinated-Generic",
    :"Vaccinated-Generic", :MulticellularOrganism, :Heterotroph, :Autotroph,
    :Lichen, :TerrestrialOrganism, :Animal, :AquaticOrganism, :Mutant,
    :Carnivore, :Extraterrestrial, :"Exotic-Foreign",...

  # It works with NARTs (but I didn't tested this functionality extensively,
  # so this might cause some problems - beware):
  genls[4]
  # => [:CollectionUnionFn, [:TheSet, :Animal, [:GroupFn, :Animal]]]

  cyc.max_specs genls[4]
  # => [:Animal, [:GroupFn, :Animal]]

  # What is more, you might even build complex subcalls, such as:
  cyc.genls? :Person, :HomoSapiens # => nil
  cyc.with_any_mt{|cyc| cyc.genls? :Person, :HomoSapiens} # => T

  # If you want to see the query which is send to Cyc, just turn on the
  # debugging:
  cyc.debug = true
  cyc.genls? :Dog, :Anial
  # Send: (genls? #$Dog #$Animal)
  # Recv: 200 T
  # => "T" 

  # The same way, you can turn it off:
  cyc.debug = false

  # Remember to close the client on exit
  cyc.close

== LICENSE:
 
(The MIT License)

Copyright (c) 2008-2010 Aleksander Pohl

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

== FEEDBACK

* mailto:apohllo@o2.pl

