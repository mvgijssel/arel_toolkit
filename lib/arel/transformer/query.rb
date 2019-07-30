module Arel
  module Transformer
    class Query
      def self.call(node, kwargs)
        node_attributes = %i[context parent]
        node_args = kwargs.slice(*node_attributes)
        object_args = kwargs.except(*node_attributes)

        node.each.select do |child_node|
          next unless matches?(child_node, node_args)

          matches?(child_node.object, object_args)
        end
      end

      def self.matches?(object, test)
        case test
        when Hash
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
