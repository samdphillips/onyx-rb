
module Onyx

    class ParseNode
        def visit_name
            ("visit_" + self.class.name.split('::').last[0...-4].downcase).to_sym
        end

        def visit(visitor, *args)
            visitor.send(visit_name, self, *args)
        end
    end

    class ExprNode < ParseNode
    end

    class SeqNode < ParseNode
        attr_reader :nodes

        def initialize(nodes=[])
            @nodes = nodes
        end

        def pretty_print(q)
            @nodes.each { |n|
                q.pp(n)
                q.text('.')
                q.breakable
            }
        end
    end

    class ImportNode < ParseNode
        attr_reader :name

        def initialize(name)
            @name = name
        end
    end

    class RefNode < ExprNode
        attr_reader :var

        def initialize(var)
            @var = var
        end

        def pretty_print(q)
            q.text(@var.to_s)
        end
    end

    class ConstNode < ExprNode
        attr_reader :value

        def initialize(value)
            @value = value
        end

        def pretty_print(q)
            q.text(@value.to_s)
        end
    end

    class CascadeNode < ExprNode
        attr_reader :rcvr, :messages

        def initialize(rcvr, messages)
            @rcvr     = rcvr
            @messages = messages
        end
    end

    class SendNode < ExprNode
        attr_reader :rcvr, :message

        def initialize(rcvr, message)
            @rcvr    = rcvr
            @message = message
        end

        def pretty_print(q)
            q.group(1, '(', ')') { q.pp(@rcvr) }
            q.pp(@message)
        end
    end

    class MessageNode < ParseNode
        attr_reader :selector, :args

        def initialize(selector, args)
            @selector = selector
            @args     = args
        end

        def primitive?
            false
        end

        def unary?
            @args.size == 0
        end

        def binary?
            @args.size == 1 and !keyword?
        end

        def keyword?
            @selector.to_s[-1] == ?:
        end

        def pretty_print(q)
            if unary? then
                q.text ' '
                q.text(selector.to_s)
            elsif binary? then
                q.breakable
                q.text(selector.to_s)
                q.breakable
                q.group(1, '(', ')') { q.pp(@args[0]) }
            else
                sel = @selector.to_s.split(':')
                @args.each_index {|i|
                    q.breakable
                    q.text(sel[i] + ':')
                    q.breakable
                    q.group(1, '(', ')') { q.pp(@args[i]) }
                }
            end
        end
    end

    class PrimMessageNode < MessageNode
        def primitive?
            true
        end
    end

    class ReturnNode < ExprNode
        attr_reader :expr

        def initialize(expr)
            @expr = expr
        end

        def pretty_print(q)
            q.text '^ '
            q.pp(@expr)
        end
    end

    class BlockNode < ExprNode
        attr_reader :args, :temps
        attr_accessor :stmts

        def initialize(args=[], temps=[], stmts=nil)
            @args = args
            @temps = temps
            @stmts = stmts
        end

        def add_temps(temps)
            @temps = temps
        end

        def pretty_print(q)
            q.group(1, '[', ']') {
                @args.each {|a|
                    q.text(':' + a.to_s)
                    q.breakable
                }
                q.text '|'
                if @temps.size > 0 then
                    q.text '|'
                    @temps.each {|t|
                        q.text(t.to_s)
                        q.breakable
                    }
                    q.text '|'
                end
                q.pp(@stmts)
            }
        end
    end
    
    class AssignNode < ExprNode
        attr_reader :var, :expr

        def initialize(var, expr)
            @var = var
            @expr = expr
        end

        def pretty_print(q)
            q.text(@var.to_s)
            q.text ' :='
            q.breakable(' ')
            q.pp(@expr)
        end
    end

    class MethodNode < ParseNode
        attr_reader :name, :args, :temps
        attr_accessor :stmts

        def initialize(name, args, temps=[], stmts=nil)
            @name = name
            @args = args
            @temps = temps
            @stmts = stmts
        end

        def add_temps(temps)
            @temps = temps
        end
    end

    class DeclNode < ParseNode
        attr_reader :name, :ivars, :trait_expr, :meta, :meths

        def initialize(name, ivars)
            @name       = name
            @ivars      = ivars
            @trait_expr = nil
            @meta       = MetaNode.new
            @meths      = []
        end

        def add_traits(trait_expr)
            @trait_expr = trait_expr
        end

        def add_meta(meta_node)
            @meta.merge(meta_node)
        end

        def add_method(method_node)
            @meths << method_node
        end
    end

    class ClassNode < DeclNode
        attr_reader :supername

        def initialize(name, supername, ivars)
            super(name, ivars)
            @supername = supername
        end
    end

    class TraitNode < DeclNode
    end

    class ClassExtNode < DeclNode
    end

    class MetaNode < ParseNode
        attr_reader :ivars, :meths

        def initialize(ivars=[])
            @ivars = ivars
            @meths = []
        end

        def add_method(method_node)
            @meths << method_node
        end

        def merge(meta_node)
            @ivars.push(*meta_node.ivars)
            @meths.push(*meta_node.meths)
        end
    end
end
