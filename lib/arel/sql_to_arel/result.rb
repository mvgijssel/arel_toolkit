module Arel
  module SqlToArel
    class Result < Array
      def to_sql(engine = Arel::Table.engine)
        sql, _binds = to_sql_and_binds(engine)
        sql
      end

      def to_sql_and_binds(engine = Arel::Table.engine)
        sql_collection = []
        binds_collection = []

        each do |item|
          sql, binds = item.to_sql_and_binds(engine)
          sql_collection << sql
          binds_collection.concat(binds) if binds
        end

        [
          sql_collection.join('; '),
          binds_collection,
        ]
      end

      def map(&block)
        Result.new super
      end
    end
  end
end
