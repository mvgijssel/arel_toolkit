# typed: false
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ParameterLists

module Arel
  module Nodes
    Arel::Table.class_eval do
      # postgres only: https://www.postgresql.org/docs/9.5/sql-select.html
      attr_accessor :only
      # postgres only: https://www.postgresql.org/docs/9.5/ddl-schemas.html
      attr_accessor :schema_name
      # postgres only: https://www.postgresql.org/docs/9.1/catalog-pg-class.html
      attr_accessor :relpersistence

      alias_method :old_initialize, :initialize
      sig { params(name: String, as: String, type_caster: ActiveRecord::TypeCaster::Map, only: T::Boolean, schema_name: String, relpersistence: String).void }
      def initialize(
        name,
        as: nil,
        type_caster: nil,
        only: false,
        schema_name: nil,
        relpersistence: 'p'
      )
        @only = only
        @schema_name = schema_name
        @relpersistence = relpersistence

        old_initialize(name, as: as, type_caster: type_caster)
      end
    end
  end

  module Visitors
    class ToSql
      alias old_visit_Arel_Table visit_Arel_Table
      sig { params(o: Arel::Table, collector: T.any(Arel::Collectors::Composite, Arel::Collectors::SQLString, Arel::Collectors::SubstituteBinds)).returns(T.any(Arel::Collectors::Composite, Arel::Collectors::SQLString, Arel::Collectors::SubstituteBinds)) }
      def visit_Arel_Table(o, collector)
        collector << 'ONLY ' if o.only

        collector << "\"#{o.schema_name}\"." if o.schema_name

        old_visit_Arel_Table(o, collector)
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Metrics/ParameterLists