
describe Onyx::Interpreter do
    subject { Onyx::Interpreter.boot }

    it "collections: OrderedCollection>>add: adds to the end of the sequence" do
        should interpret('
            c := OrderedCollection new.
            1 to: 20 do: [:i | c add: i ].
            c asArray', 
            [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20])
    end

    it "collections: OrderedCollection>>addFirst: adds to the start of the sequence" do
        should interpret('
            c := OrderedCollection new.
            1 to: 20 do: [:i | c addFirst: i ].
            c asArray', 
            [20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
    end

    it "collections: #detect: method should return the first element that matches the block" do
        should interpret('
            c := OrderedCollection new.
            1 to: 20 do: [:i | c add: i ].
            c detect: [:x | x > 5 ]', 6)
    end

    it "collections: #detect: method should return nil if no match is found" do
        should interpret('
            c := OrderedCollection new.
            1 to: 20 do: [:i | c add: i ].
            c detect: [:x | x > 20 ]', nil)
    end

    it "collections: #detect:ifNone: method should return value of block if no match is found" do
        should interpret('
            c := OrderedCollection new.
            1 to: 20 do: [:i | c add: i ].
            c detect: [:x | x > 20 ] ifNone: [ 242 ]', 242)
    end

    it "collections: #inject: 0 into: [:a :b | a + b ] method should sum the elements of the collection" do
        should interpret('
            c := OrderedCollection new.
            1 to: 5 do: [:i | c add: i ].
            c inject: 0 into: [:a :b | a + b ]', 15)
    end

    it "collections: copyFrom: 0 to: 3 method should return a copy of array" do
        should interpret('#(1 2 3 4) copyFrom: 0 to: 3', [1, 2, 3, 4])
    end

    it "collections: #select: [:x | x isOdd ] returns a collection of odd numbers" do
        should interpret('
            c := #(1 2 3 4 5 6 7).
            c select: [:x | x isOdd ]', [1, 3, 5, 7])
    end

    it "collections: OrderedCollection>>select: [:x | x isOdd ] should return collection of odds" do
        should interpret('
            c := OrderedCollection new.
            1 to: 10 do: [:i | c add: i ].
            (c select: [:x | x isOdd ]) asArray', [1, 3, 5, 7, 9])
    end

    it "litarray: literal arrays are immutable" do
        should interpret_script('spec/ost/litarray.ost', true)
    end

    it "litstring: literal strings are immutable" do
        should interpret_script('spec/ost/litstring.ost', true)
    end

    it "collections: expression arrays evaluate their contents" do
        should interpret("{3 + 4. 41 + 1}", [7, 42])
    end

    it "collections: empty expression array is empty array" do
        should interpret("{ }", [])
    end
end

