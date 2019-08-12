module Arel
  module Nodes
    class Node
      def to_sql_and_binds(engine = Arel::Table.engine)
        collector = engine.connection.send(:collector)
        engine.connection.visitor.accept(self, collector).value
      end
    end
  end
end
