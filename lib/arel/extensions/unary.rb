module Arel
  module Visitors
    class Dot
      alias visit_Arel_Nodes_Unary unary if ActiveRecord::VERSION::MAJOR < 7
    end
  end
end
