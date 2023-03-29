# rubocop:disable Naming/MethodName

module Arel
  module Attributes
    class Attribute
      module AttributeExtension
        # postgres only: https://www.postgresql.org/docs/10/ddl-schemas.html
        attr_accessor :schema_name
        attr_accessor :database
      end

      prepend AttributeExtension
    end
  end

  module Visitors
    class ToSql
      module AttributesAttributeExtension
        def visit_Arel_Attributes_Attribute(o, collector)
          collector << "#{quote_table_name(o.database)}." if o.database
          collector << "#{quote_table_name(o.schema_name)}." if o.schema_name

          super
        end
      end

      prepend AttributesAttributeExtension
    end

    class Dot
      module AttributesAttributeExtension
        def visit_Arel_Attributes_Attribute(o)
          super

          visit_edge o, 'schema_name'
          visit_edge o, 'database'
        end
      end

      prepend AttributesAttributeExtension
    end
  end
end

# rubocop:enable Naming/MethodName
