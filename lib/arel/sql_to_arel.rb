require_relative './sql_to_arel/result'
require_relative './sql_to_arel/error'
require_relative './sql_to_arel/pg_query_visitor'

module Arel
  module SqlToArel
  end

  def self.sql_to_arel(sql, binds: [])
    SqlToArel::PgQueryVisitor.new.accept(sql, binds)
  end
end
