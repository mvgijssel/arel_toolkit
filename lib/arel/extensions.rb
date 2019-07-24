require 'arel/extensions/dot'
require 'arel/extensions/unknown'
require 'arel/extensions/time_with_precision'
require 'arel/extensions/current_time'
require 'arel/extensions/current_date'
require 'arel/extensions/current_timestamp'
require 'arel/extensions/local_time'
require 'arel/extensions/local_timestamp'
require 'arel/extensions/current_role'
require 'arel/extensions/current_user'
require 'arel/extensions/session_user'
require 'arel/extensions/user'
require 'arel/extensions/current_catalog'
require 'arel/extensions/current_schema'
require 'arel/extensions/array'
require 'arel/extensions/indirection'
require 'arel/extensions/bit_string'
require 'arel/extensions/natural_join'
require 'arel/extensions/cross_join'
require 'arel/extensions/lateral'
require 'arel/extensions/range_function'
require 'arel/extensions/with_ordinality'
require 'arel/extensions/table'
require 'arel/extensions/row'
require 'arel/extensions/ordering'
require 'arel/extensions/all'
require 'arel/extensions/any'
require 'arel/extensions/array_subselect'
require 'arel/extensions/type_cast'
require 'arel/extensions/distinct_from'
require 'arel/extensions/not_distinct_from'
require 'arel/extensions/null_if'
require 'arel/extensions/similar'
require 'arel/extensions/not_similar'
require 'arel/extensions/not_between'
require 'arel/extensions/between_symmetric'
require 'arel/extensions/not_between_symmetric'
require 'arel/extensions/function'
require 'arel/extensions/factorial'
require 'arel/extensions/square_root'
require 'arel/extensions/cube_root'
require 'arel/extensions/modulo'
require 'arel/extensions/absolute'
require 'arel/extensions/bitwise_xor'
require 'arel/extensions/exponentiation'

require 'arel/extensions/contains'
unless Gem.loaded_specs.key?('postgres_ext')
  require 'arel/extensions/contained_within_equals'
  require 'arel/extensions/contains_equals'
  require 'arel/extensions/overlap'
end

require 'arel/extensions/contained_by'
require 'arel/extensions/select_statement'
require 'arel/extensions/insert_statement'
require 'arel/extensions/default_values'
require 'arel/extensions/conflict'
require 'arel/extensions/infer'
require 'arel/extensions/set_to_default'
require 'arel/extensions/update_statement'
require 'arel/extensions/current_of_expression'
require 'arel/extensions/delete_statement'
require 'arel/extensions/least'
require 'arel/extensions/greatest'
require 'arel/extensions/generate_series'
require 'arel/extensions/rank'
require 'arel/extensions/coalesce'
require 'arel/extensions/not_equal'
require 'arel/extensions/equality'
require 'arel/extensions/named_function'
require 'arel/extensions/intersect_all'
require 'arel/extensions/except_all'
require 'arel/extensions/select_manager'
require 'arel/extensions/insert_manager'
require 'arel/extensions/update_manager'
require 'arel/extensions/delete_manager'
require 'arel/extensions/at_time_zone'
require 'arel/extensions/extract_from'
require 'arel/extensions/json_get_object'
require 'arel/extensions/json_get_field'
require 'arel/extensions/json_path_get_object'
require 'arel/extensions/json_path_get_field'
require 'arel/extensions/jsonb_key_exists'
require 'arel/extensions/jsonb_any_key_exists'
require 'arel/extensions/jsonb_all_key_exists'
require 'arel/extensions/transaction'
require 'arel/extensions/assignment'
require 'arel/extensions/variable_set'
require 'arel/extensions/variable_show'
require 'arel/extensions/position'
require 'arel/extensions/overlay'
require 'arel/extensions/substring'
require 'arel/extensions/overlaps'
require 'arel/extensions/trim'
require 'arel/extensions/named_argument'
require 'arel/extensions/tree_manager'
require 'arel/extensions/into'
require 'arel/extensions/select_core'
require 'arel/extensions/unary'
require 'arel/extensions/binary'
require 'arel/extensions/unary_operation'
require 'arel/extensions/infix_operation'
require 'arel/extensions/values_list'
require 'arel/extensions/case'
require 'arel/extensions/current_row'
require 'arel/extensions/false'
require 'arel/extensions/true'
require 'arel/extensions/to_sql'
require 'arel/extensions/prepare_statement'

module Arel
  module Extensions
  end
end
