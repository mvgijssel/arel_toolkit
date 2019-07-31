module Arel
  module Visitors
    class Dot
      alias visit_ActiveRecord_TypeCaster_Map terminal
    end
  end
end
