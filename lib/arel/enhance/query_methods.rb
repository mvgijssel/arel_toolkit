module Arel
  module Enhance
    module QueryMethods
      class QueryMethod
        attr_reader :subject

        def initialize(subject)
          @subject = subject
        end
      end

      class Ancestors < QueryMethod
        def matches?(other)
          other <= subject
        end
      end

      def self.in_ancestors?(object)
        Ancestors.new(object)
      end
    end
  end
end
