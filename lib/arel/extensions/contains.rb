# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName

module Arel
  if Gem.loaded_specs.key?('postgres_ext')
    module Visitors
      module ContainsPatch
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
        def initialize(left, right)
          super(:'@>', left, right)
        end
      end
    end
  end
end

# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
