module Arel
  module Visitors
    class Dot
      alias visit_Arel_Nodes_Binary binary if ActiveRecord::VERSION::MAJOR < 7
    end
  end
end
