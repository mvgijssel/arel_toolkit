module Arel
  module Middleware
    module ActiveRecordExtension
      def load_schema!
        # Prevent Rails from memoizing an empty response when using `Arel.middleware.to_sql`.
        # Re-applying the middleware will use the database executor to fetch the actual data.
        Arel.middleware.apply(Arel.middleware.current) { super }
      end
    end
  end
end
