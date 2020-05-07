module Arel
  module Middleware
    module NoOpCache
      def self.get(key); end
      def self.set(key, sql); end
    end
  end
end

