module Arel
  module Middleware
    class Column
      attr_reader :name
      attr_reader :metadata

      def initialize(name, metadata = {})
        @name = name
        @metadata = metadata
      end
    end
  end
end
