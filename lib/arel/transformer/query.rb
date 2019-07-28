module Arel
  module Transformer
    class Query
      def self.call(node, kwargs)
        node_attributes = [:context, :parent]
        node_args = kwargs.slice(*node_attributes)
        object_args = kwargs.except(*node_attributes)

        # TODO:
        # parent refers to a Node, so the matcher probably needs to be a hash:
        # t.query(parent: { class: Arel::Table })

        # query(context: { foo: :bar })
        # should match a node with a context of { foo: :bar, papi: :chulo }
        # we're matching Hash against Hash, so in that case choose the "includes" strategy?

        # query(parent: Arel::Table)
        # which is short hand for
        # query(parent: { class: { Arel::Table } })
        # and also short hand for
        # query(parent: { object: { class: { Arel::Table } } } })
        # query(parent: { context: { range_variable: true } })

        node.each.select do |child_node|
          next unless matches?(child_node, node_args)

          matches?(child_node.object, object_args)
        end
      end

      private

      # { context: { kerk: :shine } }
      # Node.context <kerk => shine>
      def self.matches?(object, test)
        # If test value is a Hash, maybe go recursive.
        # all else test values are direct compare?
        case test
        when Hash
          # When the object is a Hash, compare hashes using subset
          # otherwise check if all members exist on object
          case object
          when Hash
            test <= object
          else
            test.all? do |test_key, test_value|
              next false unless object.respond_to?(test_key)

              object_attribute_value = object.public_send(test_key)
              matches? object_attribute_value, test_value
            end
          end
        else
          object == test
        end
      end
    end
  end
end
