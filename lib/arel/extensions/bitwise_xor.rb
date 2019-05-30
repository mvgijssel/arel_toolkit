module Arel
  module Nodes
    # TODO: `#` is bitwise xor, right? Check out:
    # -> https://www.postgresql.org/docs/9.4/functions-math.html
    # -> https://github.com/rails/rails/blob/master/activerecord/lib/arel/math.rb#L30
    # Am I wrong, or is this a bug in Arel?
    class BitwiseXor < InfixOperation
      def initialize(left, right)
        super('#', left, right)
      end
    end
  end
end
