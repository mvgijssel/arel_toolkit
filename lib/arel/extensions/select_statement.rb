# rubocop:disable Naming/MethodName

module Arel
  module Nodes
    class SelectStatement
      module SelectStatementExtension
        # For INSERT statements
        attr_accessor :values_lists
        attr_accessor :union
        attr_writer :cores
      end

      prepend SelectStatementExtension
    end
  end

  module Visitors
    class ToSql
      module SelectStatementExtension
        def visit_Arel_Nodes_SelectStatement(o, collector)
          visit(o.union, collector) if o.union
          super
        end
      end

      prepend SelectStatementExtension
    end

    class Dot
      module SelectStatementExtension
        def visit_Arel_Nodes_SelectStatement(o)
          super

          visit_edge o, 'lock'
          visit_edge o, 'with'
          visit_edge o, 'union'
          visit_edge o, 'values_lists'
        end
      end

      prepend SelectStatementExtension
    end
  end
end

# rubocop:enable Naming/MethodName
