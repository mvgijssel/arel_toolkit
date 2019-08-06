module Arel
  module SqlToArel
    class Result < Array
      def to_sql(engine = Arel::Table.engine)
        map do |item|
          item.to_sql(engine)
        end.join('; ')
      end

      def map(&block)
        Result.new super
      end
    end
  end
end
