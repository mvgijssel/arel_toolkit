# typed: false
# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  if Gem.loaded_specs.key?('postgres_ext')
    module Visitors
      module ContainsPatch
        sig { params(o: T.untyped, collector: T.untyped).returns(T.untyped) }
        def visit_Arel_Nodes_Contains(o, collector)
          if o.left.is_a?(Arel::Attribute)
            super
          else
            infix_value o, collector, ' @> '
          end
        end
      end

      PostgreSQL.prepend(ContainsPatch)
    end
  else
    module Nodes
      # https://www.postgresql.org/docs/9.1/functions-array.html
      class Contains < Arel::Nodes::InfixOperation
        sig { params(left: T.any(Arel::Nodes::Array, Arel::Nodes::TypeCast), right: T.any(Arel::Nodes::Array, Arel::Nodes::TypeCast)).void }
        def initialize(left, right)
          super(:'@>', left, right)
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName