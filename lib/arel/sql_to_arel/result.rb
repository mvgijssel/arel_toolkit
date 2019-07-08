# typed: true
module Arel
  module SqlToArel
    class Result < Array
      sig { returns(String) }
      def to_sql
        map(&:to_sql).join('; ')
      end

      sig { returns(String) }
      def to_formatted_sql
        map(&:to_formatted_sql).join('; ')
      end

      sig { params(block: Proc).returns(Arel::SqlToArel::Result) }
      def map(&block)
        Result.new super
      end
    end
  end
end