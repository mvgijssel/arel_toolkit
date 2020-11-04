# rubocop:disable Naming/MethodName
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/AbcSize

module Arel
  module Nodes
    class SelectCore < Arel::Nodes::Node
      attr_accessor :into
      attr_accessor :top

      private
      
      def hash
        [
          @source, @set_quantifier, @projections, @optimizer_hints,
          @wheres, @groups, @havings, @windows, @comment, @top, @into
        ].hash
      end
      
      def eql?(other)
        super &&
          self.top == other.top &&
          self.into == other.into
      end
    end
  end

  module Visitors
    class ToSql
      def visit_Arel_Nodes_SelectCore(o, collector)
        collector << 'SELECT'

        collector = maybe_visit o.top, collector

        collector = maybe_visit o.set_quantifier, collector

        collect_nodes_for o.projections, collector, ' '

        maybe_visit o.into, collector

        if o.source && !o.source.empty?
          collector << ' FROM '
          collector = visit o.source, collector
        end

        collect_nodes_for o.wheres, collector, ' WHERE ', ' AND '
        collect_nodes_for o.groups, collector, ' GROUP BY '
        unless o.havings.empty?
          collector << ' HAVING '
          inject_join o.havings, collector, ' AND '
        end
        collect_nodes_for o.windows, collector, ' WINDOW '

        collector
      end
    end

    class Dot
      module SelectCoreExtension
        def visit_Arel_Nodes_SelectCore(o)
          super

          visit_edge o, 'into'
          visit_edge o, 'top'
        end
      end

      prepend SelectCoreExtension
    end
  end
end

# rubocop:enable Metrics/AbcSize
# rubocop:enable Naming/MethodName
# rubocop:enable Naming/UncommunicativeMethodParamName
