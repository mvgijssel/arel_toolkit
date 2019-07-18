module Arel
  module SqlToArel
    class Result < Array
      def to_sql
        map(&:to_sql).join('; ')
      end

      def map(&block)
        Result.new super
      end
    end
  end
end
