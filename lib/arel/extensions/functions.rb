module Arel
  module Nodes
    class Least < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'LEAST', args
      end
    end

    class Greatest < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'GREATEST', args
      end
    end

    class GenerateSeries < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'GENERATE_SERIES', args
      end
    end

    class Rank < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'RANK', args
      end
    end

    class Coalesce < Arel::Nodes::NamedFunction
      def initialize(args)
        super 'COALESCE', args
      end
    end
  end
end
