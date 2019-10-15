module Arel
  module Visitors
    class Dot
      alias visit_ActiveRecord_TypeCaster_Connection terminal
    end
  end
end
