# ScheRuby

ScheRuby is a fully functional, tail call optimized Scheme interpreter written in Ruby.  It's inspired by Peter Norvig's JScheme http://norvig.com/jscheme-design.html .

It allows you to use Scheme within Ruby, or Ruby within Scheme.  Want to write a web app in Scheme? Want to implement a LISP algo in Ruby? ScheRuby lets you do it.

# Usage

1. For a REPL, complete with tab completion, run:
	ruby bin/scherepl.rb
2. To run a Scheme file, run:
	ruby bin/scheruby.rb <nameofschemefile>
3. To run Scheme from within Ruby, do:
	ScheRuby.scheme!('scheme code goes here')

# Testing

To run the unit tests:
	ruby test/test_scheruby.rb
This runs and tests a large selection of Scheme code.

There is also a suite of performance tests written in Scheme.  To run them:
	ruby bin/scheruby.rb test/performance/<nameofschemefile>
	
# Mixing Scheme and Ruby

It is possible to call Ruby methods and use Ruby objects from within Scheme, and vice versa, using a syntax inspired by the Javadot notation http://jscheme.sourceforge.net/jscheme/doc/javadot.html , and adapted to Ruby.

	$ ruby bin/scherepl.rb
	> (.reverse (.upcase "dlrow olleh"))
	"HELLO WORLD"

For now, it's not documented, but you can see examples in the tests.

# ToDo

Not all of R5RS is implemented; most specifically, macros are missing.  However, I believe enough is implemented that the rest could be implemented directly in Scheme, by simply copying in other open source Scheme packages.

Documentation, especially about calling Ruby methods from Scheme, is needed.