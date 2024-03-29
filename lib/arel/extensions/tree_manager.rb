module Arel
  class TreeManager
    # Iterate through AST, nodes will be yielded depth-first

    def to_sql_and_binds(engine = Arel::Table.engine)
      collector = engine.connection.send(:collector)
      engine.connection.visitor.accept(@ast, collector).value
    end
  end
end
