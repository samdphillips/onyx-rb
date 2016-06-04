

# onyx #

onyx has been the name for various Smalltalk implementations that I have
worked on.  This version is written in Ruby, and someday will be written
in a lower level language (if I ever get that far.)

Currently onyx is implemented as a [trampolining interpreter][tramp]
with [delimited continuations][delim] and a form of [continuation
marks][cmarks].  There is a small "standard library."

Eventually onyx will have exceptions, [traits][traits],
and [contracts][contracts].
Additionally some other pragmatics things like FFI, JIT, and all those
other expected bits of runtime infrastructure.

## Differences from "Smalltalk" ##

Here are some of the difference from other Smalltalks that are planned
on being added:

- currently no exceptions
- currently no IO system 
- currently not vm based, no bytecode
- currently no browser or other development tools


Here are some of the differences from other Smalltalks that most like
won't be added:

- methods do not implicitly return self.  Methods return the last
  expression evaluated similar to Scheme and Ruby.
- no image file
- probably something that I've forgotten besides the obvious ...

## Running Tests ##

A few different test systems are set up.

    $ rspec
    $ ruby -Ilib -I. t/tests.rb



[tramp]:     http://www.cs.indiana.edu/hyplan/sganz/publications/icfp99/paper.pdf
[delim]:     http://www.ccs.neu.edu/racket/pubs/icfp07-fyff.pdf
[cmarks]:    http://www.ccs.neu.edu/racket/pubs/dissertation-clements.pdf
[contracts]: http://www.ccs.neu.edu/racket/pubs/thesis-robby.pdf
[traits]:    http://scg.unibe.ch/archive/papers/Scha03aTraits.pdf

