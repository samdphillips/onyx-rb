
module Onyx

    class TFBranchNode < ExprNode
        def initialize(test, true_branch, false_branch)
            test.expand
            true_branch.expand
            false_branch.expand

            @test         = test
            @true_branch  = true_branch
            @false_branch = false_branch
        end

        def gen_value_code(cg)
            l1 = cg.new_label
            l2 = cg.new_label
            @test.gen_value_code(cg)
            cg.branch_false(l1)
            @true_branch.gen_value_code(cg)
            cg.branch(l2)
            cg.define_label(l1)
            @false_branch.gen_value_code(cg)
            cg.define_label(l2)
        end
    end

    class IfTrueIfFalseNode < TFBranchNode
        def self.expand(message)
            true_branch  = message.args[0]
            false_branch = message.args[1]

            if true_branch.block? and false_branch.block? then
                new(message.rcvr, true_branch.stmts, false_branch.stmts)
            else
                nil
            end
        end
    end

    class IfFalseIfTrueNode < TFBranchNode
        def self.expand(message)
            true_branch  = message.args[1]
            false_branch = message.args[0]

            if true_branch.block? and false_branch.block? then
                new(message.rcvr, true_branch.stmts, false_branch.stmts)
            else
                nil
            end
        end
    end

    class WhileFalseNode
        def self.expand(message)
            test = message.rcvr
            body = message.args[0]

            if test.block? and body.block? then
                new(test.stmts, body.stmts)
            else
                nil
            end
        end

        def initialize(test, body)
            @test = test
            @body = body
        end
    end

    MessageNode.register_special(:'ifTrue:ifFalse:', IfTrueIfFalseNode)
    MessageNode.register_special(:'ifFalse:ifTrue:', IfFalseIfTrueNode)
    MessageNode.register_special(:'whileFalse:', WhileFalseNode)
end

