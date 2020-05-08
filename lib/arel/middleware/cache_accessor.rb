module Arel
  module Middleware
    class CacheAccessor
      attr_reader :cache

      def initialize(cache)
        @cache = cache
      end

      def read(original_sql)
        cache.read cache_key(original_sql)
      end

      def write(transformed_sql:, transformed_binds:, original_sql:, original_binds:)
        # To play it safe, the order of binds was changed and therefore we won't reuse the query
        return if transformed_binds != original_binds

        cache.write(cache_key(original_sql), transformed_sql)
      end

      def cache_key_for_sql(sql)
        Digest::SHA256.hexdigest(sql)
      end

      def cache_key(sql)
        # An important aspect of this cache key method is that it includes hashes of all active
        # middlewares. If multiple Arel middleware chains that are using the same cache backend,
        # this cache key mechanism will prevent cache entries leak in the wrong chain.

        active_middleware_cache_key = Arel.middleware.current.map(&:hash).join('&') || 0
        active_middleware_cache_key + '|' + cache_key_for_sql(sql)
      end
    end
  end
end
