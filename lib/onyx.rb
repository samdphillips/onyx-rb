
require 'pp'
require 'onyx/env'
require 'onyx/lexer'
require 'onyx/nodes'
require 'onyx/obj/block'
require 'onyx/obj/char'
require 'onyx/obj/object'
require 'onyx/obj/class'
require 'onyx/obj/method'
require 'onyx/obj/ruby'
require 'onyx/obj/super'
require 'onyx/obj/trait'
require 'onyx/parser'
require 'onyx/frame'
require 'onyx/prim'
require 'onyx/interp'
require 'onyx/runner'

def main
    Onyx::Runner.run(ARGV)
end

