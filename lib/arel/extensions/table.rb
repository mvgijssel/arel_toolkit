# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ParameterLists

require 'pry'

module Arel
  class Table
    module TableExtension
      # postgres only: https://www.postgresql.org/docs/9.5/sql-select.html
      attr_accessor :only
      # postgres only: https://www.postgresql.org/docs/10/ddl-schemas.html
      attr_accessor :schema_name
      # postgres only: https://www.postgresql.org/docs/9.1/catalog-pg-class.html
      attr_accessor :relpersistence

      def initialize(
        name,
        as: nil,
        klass: nil,
        type_caster: klass&.type_caster,
        only: false,
        schema_name: nil,
        relpersistence: 'p'
      )
        @only = only
        @schema_name = schema_name
        @relpersistence = relpersistence

        super(name, klass: klass, as: as, type_caster: type_caster)
      end
    end

    prepend TableExtension
  end

  module Visitors
    class ToSql
      module TableExtension
        def visit_Arel_Table(o, collector)
          collector << 'ONLY ' if o.only

          case o.relpersistence
          when 'p'
            collector << ''

          when 'u'
            collector << 'UNLOGGED '

          when 't'
            collector << 'TEMPORARY '

          else
            raise "Unknown relpersistence `#{o.relpersistence}`"
          end

          collector << "\"#{o.schema_name}\"." if o.schema_name

          super
        end
      end

      prepend TableExtension
    end

    class Dot
      module TableExtension
        def visit_Arel_Table(o)
          super

          visit_edge o, 'only'
          visit_edge o, 'schema_name'
          visit_edge o, 'relpersistence'
          visit_edge o, 'type_caster'
        end
      end

      prepend TableExtension
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Metrics/ParameterLists
