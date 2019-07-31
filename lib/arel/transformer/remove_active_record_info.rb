module Arel
  module Transformer
    class RemoveActiveRecordInfo
      class << self
        def call(arel, _context)
          tree = Arel.enhance(arel)

          tree.query(class: Arel::Table).each do |node|
            node['type_caster'].remove
          end

          tree.query(class: Arel::Nodes::BindParam).each do |node|
            node.replace(
              cast_for_database(node.object.value.value_for_database),
            )
          end

          tree.object
        end

        private

        def cast_for_database(value)
          case value
          when String
            Arel.sql("\"#{value}\"")
          when Integer
            value
          when TrueClass
            Arel::Nodes::TypeCast.new(Arel::Nodes::Quoted.new('t'), 'bool')
          when FalseClass
            Arel::Nodes::TypeCast.new(Arel::Nodes::Quoted.new('f'), 'bool')
          when Float
            value
          else
            raise "Unknown value cast `#{value}` with class `#{value.class}`"
          end
        end
      end
    end
  end
end
