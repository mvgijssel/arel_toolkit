# rubocop:disable Naming/MethodName

module Arel
  module Visitors
    class Dot
      def visit_ActiveModel_Attribute_WithCastValue(o)
        visit_edge o, 'name'
        visit_edge o, 'value_before_type_cast'
      end
    end

    class ToSql
      def visit_ActiveModel_Attribute_WithCastValue(o, collector)
        visit(o.value_for_database, collector)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
