module Arel
  module Middleware
    module NoOpCache
      def self.read(key); end

      def self.write(key, sql); end
    end
  end
end
