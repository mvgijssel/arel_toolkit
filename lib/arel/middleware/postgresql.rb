require_relative './postgresql/bridge'
require_relative './postgresql/bridge/column'
require_relative './postgresql/adapter'
require_relative './postgresql/result'

module Arel
  module Middleware
    module Postgresql
    end
  end
end
