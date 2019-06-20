require 'arel/sql_to_arel/result'
require 'arel/sql_to_arel/pg_query_visitor'

module Arel
  def self.sql_to_arel(sql, binds: [])
    SqlToArel::PgQueryVisitor.new.accept(sql, binds)
  end
end
