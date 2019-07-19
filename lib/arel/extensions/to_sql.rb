# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  module Visitors
    class ToSql
      def visit_Arel_Attributes_Attribute(o, collector)
        if o.relation
          join_name = o.relation.table_alias || o.relation.name
          collector << "#{quote_table_name join_name}.#{quote_column_name o.name}"
        else
          visit_Arel_Nodes_UnqualifiedColumn o, collector
        end
      end

      alias visit_Arel_Attributes_Integer visit_Arel_Attributes_Attribute
      alias visit_Arel_Attributes_Float visit_Arel_Attributes_Attribute
      alias visit_Arel_Attributes_Decimal visit_Arel_Attributes_Attribute
      alias visit_Arel_Attributes_String visit_Arel_Attributes_Attribute
      alias visit_Arel_Attributes_Time visit_Arel_Attributes_Attribute
      alias visit_Arel_Attributes_Boolean visit_Arel_Attributes_Attribute
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
