module Arel
  class TreeManager
    # Iterate through AST, nodes will be yielded depth-first
    def each(&block)
      return enum_for(:each) unless block_given?

      ::Arel::Visitors::DepthFirst.new(block).accept ast
    end
  end
end
