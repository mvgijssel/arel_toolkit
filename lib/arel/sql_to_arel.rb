# typed: true
require 'arel/sql_to_arel/result'
require 'arel/sql_to_arel/error'
require 'arel/sql_to_arel/pg_query_visitor'

module Arel
  sig do
    params(
      sql: String,
      binds: T::Array,
    ).returns(Arel::SqlToArel::Result)
  end
  def self.sql_to_arel(sql, binds: [])
    SqlToArel::PgQueryVisitor.new.accept(sql, binds)
  end
end
