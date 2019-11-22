module Arel
  module Transformer
    class AttributesWithTable
      def call(arel, next_middleware)
        tree = Arel.enhance(arel)

        update_arel_attributes tree

        next_middleware.call tree
      end

      def update_arel_attributes(tree)
        tree.query(class: Arel::Nodes::UnqualifiedColumn).each do |node|
          binding.pry
          puts node.to_sql
        end
      end
    end
  end
end
