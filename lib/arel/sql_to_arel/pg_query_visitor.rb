# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Naming/MethodName
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize

require 'pg_query'
require_relative './pg_query_visitor/frame_options'

module Arel
  module SqlToArel
    class PgQueryVisitor
      PG_CATALOG = 'pg_catalog'.freeze
      MIN_MAX_EXPR = 'MinMaxExpr'.freeze

      attr_reader :object
      attr_reader :binds
      attr_reader :sql

      def accept(sql, binds = [])
        tree = PgQuery.parse(sql).tree

        @object = tree
        @binds = binds
        @sql = sql

        Result.new visit(object.stmts, :top)
      rescue ::PgQuery::ParseError => e
        new_error = ::PgQuery::ParseError.new(e.message, __FILE__, __LINE__, -1)
        raise new_error, e.message, e.backtrace
      rescue ::StandardError => e
        raise e.class, e.message, e.backtrace if e.is_a?(Arel::SqlToArel::Error)

        boom e.message, e.backtrace
      end

      private

      def visit_A_ArrayExpr(attribute)
        Arel::Nodes::Array.new visit(attribute.elements)
      end

      def visit_A_Const(attribute)
        visit(attribute.val, :const)
      end

      def visit_A_Expr(attribute)
        case attribute.kind
        when :AEXPR_OP
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr) if attribute.rexpr
          operator = visit(attribute.name[0], :operator)
          generate_operator(left, right, operator)

        when :AEXPR_OP_ANY
          left = visit(attribute.lexpr)
          right = visit(attribute.rexpr)
          right = Arel::Nodes::Any.new right
          operator = visit(attribute.name[0], :operator)
          generate_operator(left, right, operator)

        when :AEXPR_OP_ALL
          left = visit(attribute.lexpr)
          right = visit(attribute.rexpr)
          right = Arel::Nodes::All.new right
          operator = visit(attribute.name[0], :operator)
          generate_operator(left, right, operator)

        when :AEXPR_DISTINCT
          left = visit(attribute.lexpr)
          right = visit(attribute.rexpr)
          Arel::Nodes::DistinctFrom.new(left, right)

        when :AEXPR_NOT_DISTINCT
          left = visit(attribute.lexpr)
          right = visit(attribute.rexpr)
          Arel::Nodes::NotDistinctFrom.new(left, right)

        when :AEXPR_NULLIF
          left = visit(attribute.lexpr)
          right = visit(attribute.rexpr)
          Arel::Nodes::NullIf.new(left, right)

        when :AEXPR_IN
          left = visit(attribute.lexpr)
          right = visit(attribute.rexpr)
          operator = visit(attribute.name[0], :operator)

          if operator == '<>'
            Arel::Nodes::NotIn.new(left, right)
          else
            Arel::Nodes::In.new(left, right)
          end

        when :AEXPR_LIKE, :AEXPR_ILIKE
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr)
          escape = nil

          if right.is_a?(Array)
            boom "Don't know how to handle length `#{right.length}`" if right.length != 2

            right, escape = right
          end

          operator = visit(attribute.name[0], :operator)

          if %w[~~ ~~*].include?(operator)
            Arel::Nodes::Matches.new(left, right, escape, attribute.kind == :AEXPR_LIKE)
          else
            Arel::Nodes::DoesNotMatch.new(left, right, escape, attribute.kind == :AEXPR_LIKE)
          end
        when :AEXPR_SIMILAR
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr)
          escape = nil

          right, escape = right if right.is_a?(Array)

          operator = visit(attribute.name[0], :operator)

          if operator == '~'
            Arel::Nodes::Similar.new(left, right, escape)
          else
            Arel::Nodes::NotSimilar.new(left, right, escape)
          end

        when :AEXPR_BETWEEN
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr)
          Arel::Nodes::Between.new left, Arel::Nodes::And.new(right)

        when :AEXPR_NOT_BETWEEN
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr)
          Arel::Nodes::NotBetween.new left, Arel::Nodes::And.new(right)

        when :AEXPR_BETWEEN_SYM
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr)
          Arel::Nodes::BetweenSymmetric.new left, Arel::Nodes::And.new(right)

        when :AEXPR_NOT_BETWEEN_SYM
          left = visit(attribute.lexpr) if attribute.lexpr
          right = visit(attribute.rexpr)
          Arel::Nodes::NotBetweenSymmetric.new left, Arel::Nodes::And.new(right)

        else
          boom "Unknown Expr type `#{attribute.kind}`"
        end
      end

      def visit_A_Indices(attribute, context)
        visit attribute.uidx, context
      end

      def visit_A_Indirection(attribute)
        Arel::Nodes::Indirection.new(visit(attribute.arg), visit(attribute.indirection, :operator))
      end

      def visit_A_Star(_attribute)
        Arel.star
      end

      def visit_Alias(attribute)
        aliasname = if attribute.respond_to?(:aliasname)
                      attribute.aliasname
                    elsif attribute.is_a?(Hash)
                      attribute[:aliasname]
                    end

        return if aliasname.nil?

        Arel.sql visit_String(aliasname, nil)
      end

      def visit_BitString(attribute)
        Arel::Nodes::BitString.new(attribute.str)
      end

      def visit_BoolExpr(attribute, context = false)
        args = visit(attribute.args, context || true)

        result = case attribute.boolop
                 when :AND_EXPR
                   Arel::Nodes::And.new(args)
                 when :OR_EXPR
                   generate_boolean_expression(args, Arel::Nodes::Or)
                 when :NOT_EXPR
                   Arel::Nodes::Not.new(args)
                 else
                   boom "? Boolop -> #{boolop}"
                 end

        if context
          Arel::Nodes::Grouping.new(result)
        else
          result
        end
      end

      def visit_BooleanTest(attribute)
        arg = visit(attribute.arg)

        case attribute.booltesttype
        when :IS_TRUE
          Arel::Nodes::Equality.new(arg, Arel::Nodes::True.new)
        when :IS_NOT_TRUE
          Arel::Nodes::NotEqual.new(arg, Arel::Nodes::True.new)
        when :IS_FALSE
          Arel::Nodes::Equality.new(arg, Arel::Nodes::False.new)
        when :IS_NOT_FALSE
          Arel::Nodes::NotEqual.new(arg, Arel::Nodes::False.new)
        when :IS_UNKNOWN
          Arel::Nodes::Equality.new(arg, Arel::Nodes::Unknown.new)
        when :IS_NOT_UNKNOWN
          Arel::Nodes::NotEqual.new(arg, Arel::Nodes::Unknown.new)
        else
          boom '?'
        end
      end

      def visit_CaseExpr(attribute)
        Arel::Nodes::Case.new.tap do |kees|
          kees.case = visit(attribute.arg) if attribute.arg

          kees.conditions = visit attribute.args

          if attribute.defresult
            default_result = visit(attribute.defresult, :sql)

            kees.default = Arel::Nodes::Else.new default_result
          end
        end
      end

      def visit_CaseWhen(attribute)
        expr = visit(attribute.expr)
        result = visit(attribute.result)

        Arel::Nodes::When.new(expr, result)
      end

      def visit_CoalesceExpr(attribute)
        args = visit(attribute.args)

        Arel::Nodes::Coalesce.new args
      end

      def visit_ColumnRef(attribute)
        fields = attribute.fields.reverse
        column = visit(fields[0], :operator)
        table = visit(fields[1], :operator) if fields[1]
        schema_name = visit(fields[2], :operator) if fields[2]
        database = visit(fields[3], :operator) if fields[3]

        table = Arel::Table.new(table) if table
        attribute = Arel::Attribute.new(table, column)
        attribute.schema_name = schema_name
        attribute.database = database

        return attribute if table

        Arel::Nodes::UnqualifiedColumn.new Arel::Attribute.new(nil, column)
      end

      def visit_CommonTableExpr(attribute)
        cte_table = Arel::Table.new(attribute.ctename)
        cte_definition = visit(attribute.ctequery)
        Arel::Nodes::As.new(cte_table, Arel::Nodes::Grouping.new(cte_definition))
      end

      def visit_CurrentOfExpr(attribute)
        Arel::Nodes::CurrentOfExpression.new(attribute.cursor_name)
      end

      def visit_DeallocateStmt(attribute)
        Arel::Nodes::Dealocate.new attribute.name.presence
      end

      def visit_DefElem(attribute)
        case attribute.defname
        when 'savepoint_name'
          visit(attribute.arg)
        else
          boom "Unknown defname `#{attribute.defname}` with defaction `#{attribute.defaction}`"
        end
      end

      def visit_DeleteStmt(attribute)
        relation = visit(attribute.relation)

        delete_manager = Arel::DeleteManager.new
        delete_statement = delete_manager.ast
        delete_statement.relation = relation
        delete_statement.using = visit(attribute.using_clause) if attribute.using_clause
        delete_statement.wheres = attribute.where_clause ? [visit(attribute.where_clause)] : []
        delete_statement.with = visit(attribute.with_clause) if attribute.with_clause
        delete_statement.returning = visit(attribute.returning_list, :select)
        delete_manager
      end

      def visit_Float(attribute)
        Arel::Nodes::SqlLiteral.new attribute.str
      end

      # https://github.com/postgres/postgres/blob/REL_10_1/src/include/nodes/parsenodes.h
      def visit_FuncCall(attribute)
        args = if attribute.args.present?
                 visit attribute.args
               elsif attribute.agg_star
                 [Arel.star]
               else
                 []
               end

        function_names = visit(attribute.funcname, :operator)

        func = case function_names
               when ['sum']
                 Arel::Nodes::Sum.new args
               when ['count']
                 Arel::Nodes::Count.new args
               when ['max']
                 Arel::Nodes::Max.new args
               when ['min']
                 Arel::Nodes::Min.new args
               when ['avg']
                 Arel::Nodes::Avg.new args
               when [PG_CATALOG, 'like_escape']
                 args
               when [PG_CATALOG, 'similar_to_escape']
                 args
               when [PG_CATALOG, 'date_part']
                 field, expression = args
                 [Arel::Nodes::ExtractFrom.new(expression, field)]
               when [PG_CATALOG, 'timezone']
                 timezone, expression = args
                 [Arel::Nodes::AtTimeZone.new(maybe_add_grouping(expression), timezone)]
               # https://www.postgresql.org/docs/10/functions-string.html
               when [PG_CATALOG, 'position']
                 string, substring = args
                 [Arel::Nodes::Position.new(substring, string)]
               when [PG_CATALOG, 'overlay']
                 string, substring, start, length = args
                 [Arel::Nodes::Overlay.new(string, substring, start, length)]
               when [PG_CATALOG, 'ltrim']
                 string, substring = args
                 [Arel::Nodes::Trim.new('leading', substring, string)]
               when [PG_CATALOG, 'rtrim']
                 string, substring = args
                 [Arel::Nodes::Trim.new('trailing', substring, string)]
               when [PG_CATALOG, 'btrim']
                 string, substring = args
                 [Arel::Nodes::Trim.new('both', substring, string)]
               when [PG_CATALOG, 'substring']
                 string, pattern, escape = args
                 [Arel::Nodes::Substring.new(string, pattern, escape)]
               when [PG_CATALOG, 'overlaps']
                 start1, end1, start2, end2 = args
                 [Arel::Nodes::Overlaps.new(start1, end1, start2, end2)]
               else
                 case function_names.length
                 when 2
                   func = Arel::Nodes::NamedFunction.new(function_names.last, args)
                   func.schema_name = function_names.first
                   func
                 when 1
                   Arel::Nodes::NamedFunction.new(function_names.first, args)
                 else
                   boom "Don't know how to handle function names length `#{function_names.length}`"
                 end
               end

        func.distinct = attribute.agg_distinct unless func.is_a?(::Array)
        func.orders = (attribute.agg_order ? visit(attribute.agg_order) : []) unless
          func.is_a?(::Array)
        func.filter = (attribute.agg_filter ? visit(attribute.agg_filter) : nil) unless
          func.is_a?(::Array)
        func.within_group = attribute.agg_within_group unless func.is_a?(::Array)
        func.variardic = attribute.func_variadic unless func.is_a?(::Array)

        if attribute.over
          Arel::Nodes::Over.new(func, visit(attribute.over))
        else
          func
        end
      end

      def visit_InferClause(attribute)
        left = Arel.sql(attribute.conname) if attribute.conname
        right = visit(attribute.index_elems) if attribute.index_elems.present?
        Arel::Nodes::Infer.new left, right
      end

      def visit_IndexElem(attribute)
        boom "Unknown ordering `#{attribute.ordering}`" unless attribute.ordering == :SORTBY_DEFAULT
        boom "Unknown nulls ordering `#{attribute.nulls_ordering}`" unless
          attribute.nulls_ordering == :SORTBY_NULLS_DEFAULT

        Arel.sql visit_String(attribute.name)
      end

      def visit_InsertStmt(attribute)
        relation = visit(attribute.relation)
        cols = visit(attribute.cols, :insert).map do |col|
          Arel::Attribute.new(relation, col)
        end

        insert_manager = Arel::InsertManager.new
        insert_statement = insert_manager.ast
        insert_statement.relation = relation
        insert_statement.columns = cols
        insert_statement.override = attribute.override
        insert_statement.with = visit(attribute.with_clause) if attribute.with_clause

        insert_statement.values = if attribute.select_stmt.present?
                                    select_stmt = visit(attribute.select_stmt)
                                    insert_statement.values = select_stmt.values_lists if
                                      select_stmt.present?
                                  else
                                    insert_statement.values = Arel::Nodes::DefaultValues.new
                                  end

        insert_statement.returning = visit(attribute.returning_list, :select)
        insert_statement.conflict = visit(attribute.on_conflict_clause) if
          attribute.on_conflict_clause
        insert_manager
      end

      def visit_Integer(attribute)
        attribute.ival
      end

      def visit_IntoClause(attribute)
        raise "Unknown on_commit `#{attribute.on_commit}`" unless
          attribute.on_commit == :ONCOMMIT_NOOP

        Arel::Nodes::Into.new(visit(attribute.rel))
      end

      def visit_JoinExpr(attribute)
        join_class = case attribute.jointype
                     when :JOIN_INNER
                       if attribute.is_natural
                         Arel::Nodes::NaturalJoin
                       elsif attribute.quals.nil?
                         Arel::Nodes::CrossJoin
                       else
                         Arel::Nodes::InnerJoin
                       end
                     when :JOIN_LEFT
                       Arel::Nodes::OuterJoin
                     when :JOIN_FULL
                       Arel::Nodes::FullOuterJoin
                     when :JOIN_RIGHT
                       Arel::Nodes::RightOuterJoin
                     end

        larg = visit(attribute.larg)
        rarg = visit(attribute.rarg)

        join = if attribute.quals
                 join_class.new(rarg, Arel::Nodes::On.new(visit(attribute.quals)))
               else
                 join_class.new(rarg, nil)
               end

        if larg.is_a?(Array)
          larg.concat([join])
        else
          [larg, join]
        end
      end

      def visit_LockingClause(attribute)
        strength_clause = {
          LCS_FORKEYSHARE: 'FOR KEY SHARE',
          LCS_FORSHARE: 'FOR SHARE',
          LCS_FORNOKEYUPDATE: 'FOR NO KEY UPDATE',
          LCS_FORUPDATE: 'FOR UPDATE',
        }.fetch(attribute.strength)
        wait_policy_clause = {
          LockWaitBlock: '',
          LockWaitSkip: ' SKIP LOCKED',
          LockWaitError: ' NOWAIT',
        }.fetch(attribute.wait_policy)

        Arel::Nodes::Lock.new Arel.sql("#{strength_clause}#{wait_policy_clause}")
      end

      def visit_MinMaxExpr(attribute)
        case attribute.op
        when :IS_GREATEST
          Arel::Nodes::Greatest.new visit(attribute.args)
        when :IS_LEAST
          Arel::Nodes::Least.new visit(attribute.args)
        else
          boom "Unknown Op -> #{attribute.op}"
        end
      end

      def visit_NamedArgExpr(attribute)
        arg = visit(attribute.arg)
        boom '' unless attribute.argnumber == -1

        Arel::Nodes::NamedArgument.new(attribute.name, arg)
      end

      def visit_Node(attribute, context = nil)
        return attribute.list.items.map { |item| visit_Node(item, context) } if
          attribute.node == :list

        visit(attribute[attribute.node.to_s], context)
      end

      def visit_Null(_attribute)
        Arel.sql 'NULL'
      end

      def visit_NullTest(attribute)
        arg = visit(attribute.arg)

        case attribute.nulltesttype
        when :IS_NULL
          Arel::Nodes::Equality.new(arg, nil)
        when :IS_NOT_NULL
          Arel::Nodes::NotEqual.new(arg, nil)
        end
      end

      def visit_OnConflictClause(attribute)
        conflict = Arel::Nodes::Conflict.new
        conflict.action = attribute.action
        conflict.infer = visit(attribute.infer) if attribute.infer
        conflict.values = attribute.target_list ? visit(attribute.target_list, :update) : []
        conflict.wheres = attribute.where_clause ? [visit(attribute.where_clause)] : []
        conflict
      end

      def visit_ParamRef(attribute)
        value = (binds[attribute.number - 1] unless binds.empty?)

        Arel::Nodes::BindParam.new(value)
      end

      def visit_PrepareStmt(attribute)
        Arel::Nodes::Prepare.new(
          attribute.name,
          attribute.argtypes.present? && visit(attribute.argtypes),
          visit(attribute.query),
        )
      end

      def visit_RangeFunction(attribute)
        functions = attribute.functions.map do |function_array|
          function, _empty_node = function_array.list.items

          visit(function)
        end

        node = Arel::Nodes::RangeFunction.new functions, is_rowsfrom: attribute.is_rowsfrom
        node = attribute.lateral ? Arel::Nodes::Lateral.new(node) : node
        node = attribute.ordinality ? Arel::Nodes::WithOrdinality.new(node) : node
        attribute.alias.nil? ? node : Arel::Nodes::As.new(node, visit(attribute.alias))
      end

      def visit_RangeSubselect(attribute)
        aliaz = visit(attribute.alias)
        subquery = visit(attribute.subquery)
        node = Arel::Nodes::As.new(Arel::Nodes::Grouping.new(subquery), aliaz)
        attribute.lateral ? Arel::Nodes::Lateral.new(node) : node
      end

      def visit_RangeVar(attribute)
        Arel::Table.new(
          attribute.relname,
          as: (visit(attribute.alias) if attribute.alias),
          only: !attribute.inh,
          relpersistence: attribute.relpersistence,
          schema_name: attribute.schemaname.blank? ? nil : attribute.schemaname,
        )
      end

      def visit_RawStmt(attribute, context)
        visit(attribute.stmt, context)
      end

      def visit_ResTarget(attribute, context)
        case context
        when :select
          val = visit(attribute.val)

          if attribute.name.blank?
            val
          else
            aliaz = visit_Alias(aliasname: attribute.name)
            Arel::Nodes::As.new(val, aliaz)
          end
        when :insert
          attribute.name
        when :update
          relation = nil
          column = Arel::Attribute.new(relation, attribute.name)
          value = visit(attribute.val)

          Nodes::Assignment.new(Nodes::UnqualifiedColumn.new(column), value)
        else
          boom "Unknown context `#{context}`"
        end
      end

      def visit_RowExpr(attribute)
        Arel::Nodes::Row.new(visit(attribute.args), attribute.row_format)
      end

      def visit_SelectStmt(attribute, context = nil)
        select_manager = Arel::SelectManager.new
        select_core = select_manager.ast.cores.last
        select_statement = select_manager.ast

        froms, join_sources = generate_sources(attribute.from_clause)
        if froms
          froms = froms.first if froms.length == 1
          select_core.froms = froms
        end

        select_core.from = froms if froms
        select_core.source.right = join_sources

        select_core.projections = visit(attribute.target_list, :select) if attribute.target_list

        if attribute.where_clause
          where_clause = visit(attribute.where_clause)
          where_clause = if where_clause.is_a?(Arel::Nodes::And)
                           where_clause
                         else
                           Arel::Nodes::And.new([where_clause])
                         end

          select_core.wheres = [where_clause]
        end

        select_core.groups = visit(attribute.group_clause) if attribute.group_clause
        select_core.havings = [visit(attribute.having_clause)] if attribute.having_clause
        select_core.windows = visit(attribute.window_clause) if attribute.window_clause
        select_core.into = visit(attribute.into_clause) if attribute.into_clause
        select_core.top = ::Arel::Nodes::Top.new visit(attribute.limit_count) if
          attribute.limit_count

        if attribute.distinct_clause == []
          select_core.set_quantifier = nil
        elsif attribute.distinct_clause.is_a?(Google::Protobuf::RepeatedField)
          select_core.set_quantifier = if attribute.distinct_clause.size == 1 &&
                                          attribute.distinct_clause.first.to_h.compact.length.zero?
                                         Arel::Nodes::Distinct.new
                                       else
                                         Arel::Nodes::DistinctOn.new(
                                           visit(attribute.distinct_clause),
                                         )
                                       end
        elsif attribute.distinct_clause.nil?
          select_core.set_quantifier = nil
        else
          boom "Unknown distinct clause `#{attribute.distinct_clause}`"
        end

        if attribute.limit_count
          select_statement.limit = ::Arel::Nodes::Limit.new visit(attribute.limit_count)
        end
        if attribute.limit_offset
          select_statement.offset = ::Arel::Nodes::Offset.new visit(attribute.limit_offset)
        end
        select_statement.orders = visit(attribute.sort_clause.to_a)
        select_statement.with = visit(attribute.with_clause) if attribute.with_clause
        select_statement.lock = visit(attribute.locking_clause) if attribute.locking_clause.present?

        if attribute.values_lists.present?
          values_lists = visit(attribute.values_lists).map do |values_list|
            values_list.map do |value|
              case value
              when String
                value
              when Integer
                Arel.sql(value.to_s)
              when Arel::Nodes::TypeCast, Arel::Nodes::UnqualifiedColumn
                Arel.sql(value.to_sql)
              when Arel::Nodes::BindParam
                value
              when Arel::Nodes::Quoted
                value.value
              else
                boom "Unknown value `#{value}`"
              end
            end
          end
          select_statement.values_lists = Arel::Nodes::ValuesList.new(values_lists)
        end

        union = case attribute.op
                when :SET_OPERATION_UNDEFINED, :SETOP_NONE
                  nil
                when :SETOP_UNION
                  if attribute.all
                    Arel::Nodes::UnionAll.new(visit(attribute.larg), visit(attribute.rarg))
                  else
                    Arel::Nodes::Union.new(visit(attribute.larg), visit(attribute.rarg))
                  end
                when :SETOP_INTERSECT
                  if attribute.all
                    Arel::Nodes::IntersectAll.new(visit(attribute.larg), visit(attribute.rarg))
                  else
                    Arel::Nodes::Intersect.new(visit(attribute.larg), visit(attribute.rarg))
                  end
                when :SETOP_EXCEPT
                  if attribute.all
                    Arel::Nodes::ExceptAll.new(visit(attribute.larg), visit(attribute.rarg))
                  else
                    Arel::Nodes::Except.new(visit(attribute.larg), visit(attribute.rarg))
                  end
                else
                  # https://www.postgresql.org/docs/10/queries-union.html
                  boom "Unknown combining queries op `#{attribute.op}`"
                end

        unless union.nil?
          select_statement.cores = []
          select_statement.union = union
        end

        if context == :top
          select_manager
        else
          select_statement
        end
      end

      def visit_SetToDefault(_args)
        Arel::Nodes::SetToDefault.new
      end

      def visit_SortBy(attribute)
        result = visit(attribute.node)
        case attribute.sortby_dir
        when :SORTBY_ASC
          Arel::Nodes::Ascending.new(
            result,
            PgQuery::SortByNulls.descriptor.to_h[attribute.sortby_nulls] - 1,
          )
        when :SORTBY_DESC
          Arel::Nodes::Descending.new(
            result,
            PgQuery::SortByNulls.descriptor.to_h[attribute.sortby_nulls] - 1,
          )
        else
          result
        end
      end

      def visit_SQLValueFunction(attribute)
        {
          SVFOP_CURRENT_DATE: -> { Arel::Nodes::CurrentDate.new },
          SVFOP_CURRENT_TIME: -> { Arel::Nodes::CurrentTime.new },
          SVFOP_CURRENT_TIME_N: -> { Arel::Nodes::CurrentTime.new(precision: attribute.typmod) },
          SVFOP_CURRENT_TIMESTAMP: -> { Arel::Nodes::CurrentTimestamp.new },
          SVFOP_CURRENT_TIMESTAMP_N: lambda {
            Arel::Nodes::CurrentTimestamp.new(precision: attribute.typmod)
          },
          SVFOP_LOCALTIME: -> { Arel::Nodes::LocalTime.new },
          SVFOP_LOCALTIME_N: -> { Arel::Nodes::LocalTime.new(precision: attribute.typmod) },
          SVFOP_LOCALTIMESTAMP: -> { Arel::Nodes::LocalTimestamp.new },
          SVFOP_LOCALTIMESTAMP_N: lambda {
            Arel::Nodes::LocalTimestamp.new(precision: attribute.typmod)
          },
          SVFOP_CURRENT_ROLE: -> { Arel::Nodes::CurrentRole.new },
          SVFOP_CURRENT_USER: -> { Arel::Nodes::CurrentUser.new },
          SVFOP_USER: -> { Arel::Nodes::User.new },
          SVFOP_SESSION_USER: -> { Arel::Nodes::SessionUser.new },
          SVFOP_CURRENT_CATALOG: -> { Arel::Nodes::CurrentCatalog.new },
          SVFOP_CURRENT_SCHEMA: -> { Arel::Nodes::CurrentSchema.new },
        }[attribute.op].call
      end

      def visit_String(attribute, context = nil)
        case context
        when :operator
          attribute.str
        when :const
          Arel::Nodes.build_quoted attribute.str
        else
          "\"#{attribute}\""
        end
      end

      def visit_SubLink(attribute)
        subselect = visit(attribute.subselect)
        testexpr = visit(attribute.testexpr) if attribute.testexpr
        operator = if attribute.oper_name
                     operator = visit(attribute.oper_name, :operator)
                     boom 'Unable to handle operator length > 1' if operator.length > 1

                     operator.first
                   end

        generate_sublink(attribute.sub_link_type, subselect, testexpr, operator)
      end

      def visit_TransactionStmt(attribute)
        Arel::Nodes::Transaction.new(
          PgQuery::TransactionStmtKind.descriptor.to_h[attribute.kind],
          visit_String(attribute.savepoint_name),
        )
      end

      def visit_TypeCast(attribute)
        arg = visit(attribute.arg)
        type_name = visit(attribute.type_name)

        Arel::Nodes::TypeCast.new(maybe_add_grouping(arg), type_name)
      end

      def visit_TypeName(attribute)
        array_bounds = visit(attribute.array_bounds)

        names = attribute.names.map do |name|
          visit(name, :operator)
        end

        names = names.reject { |name| name == PG_CATALOG }

        boom 'https://github.com/mvgijssel/arel_toolkit/issues/40' if attribute.typemod != -1
        boom 'https://github.com/mvgijssel/arel_toolkit/issues/41' if names.length > 1
        if array_bounds != [] && array_bounds != [-1]
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/86'
        end

        type_name = names.first
        type_name = case type_name
                    when 'int4'
                      'integer'
                    when 'float4'
                      'real'
                    when 'float8'
                      'double precision'
                    when 'timestamptz'
                      'timestamp with time zone'
                    else
                      type_name
                    end

        type_name += '[]' if array_bounds == [-1]
        type_name
      end

      def visit_UpdateStmt(attribute)
        relation = visit(attribute.relation)
        target_list = visit(attribute.target_list, :update)

        update_manager = Arel::UpdateManager.new
        update_statement = update_manager.ast
        update_statement.relation = relation
        update_statement.froms = visit(attribute.from_clause)
        update_statement.values = target_list
        update_statement.wheres = attribute.where_clause ? [visit(attribute.where_clause)] : []
        update_statement.with = visit(attribute.with_clause) if attribute.with_clause
        update_statement.returning = visit(attribute.returning_list, :select)
        update_manager
      end

      def visit_VariableSetStmt(attribute)
        Arel::Nodes::VariableSet.new(
          attribute.kind,
          visit(attribute.args),
          attribute.name,
          attribute.is_local,
        )
      end

      def visit_VariableShowStmt(attribute)
        Arel::Nodes::VariableShow.new(attribute.name)
      end

      def visit_WindowDef(attribute)
        if attribute.name.present? &&
           attribute.partition_clause.empty? &&
           attribute.order_clause.empty?
          return Arel::Nodes::SqlLiteral.new(attribute.name)
        end

        instance = if attribute.name.blank?
                     Arel::Nodes::Window.new
                   else
                     Arel::Nodes::NamedWindow.new(attribute.name)
                   end

        instance.tap do |window|
          window.orders = visit attribute.order_clause
          window.partitions = visit attribute.partition_clause

          if attribute.frame_options
            window.framing = FrameOptions.arel(
              attribute.frame_options,
              (visit(attribute.start_offset) if attribute.start_offset),
              (visit(attribute.end_offset) if attribute.end_offset),
            )
          end
        end
      end

      def visit_WithClause(attribute)
        if attribute.recursive
          Arel::Nodes::WithRecursive.new visit(attribute.ctes)
        else
          Arel::Nodes::With.new visit(attribute.ctes)
        end
      end

      def generate_operator(left, right, operator)
        left = maybe_add_grouping(left)
        right = maybe_add_grouping(right)

        case operator

        # https://www.postgresql.org/docs/10/functions-math.html
        when '+'
          Arel::Nodes::Addition.new(left, right)
        when '-'
          if left.nil?
            Arel::Nodes::UnaryOperation.new(:'-', right)
          else
            Arel::Nodes::Subtraction.new(left, right)
          end
        when '*'
          Arel::Nodes::Multiplication.new(left, right)
        when '/'
          Arel::Nodes::Division.new(left, right)
        when '%'
          Arel::Nodes::Modulo.new(left, right)
        when '^'
          Arel::Nodes::Exponentiation.new(left, right)
        when '|/'
          Arel::Nodes::SquareRoot.new(right)
        when '||/'
          Arel::Nodes::CubeRoot.new(right)
        when '!'
          Arel::Nodes::Factorial.new(left || right, false)
        when '!!'
          Arel::Nodes::Factorial.new(right, true)
        when '@'
          Arel::Nodes::Absolute.new(right)
        when '&'
          Arel::Nodes::BitwiseAnd.new(left, right)
        when '|'
          Arel::Nodes::BitwiseOr.new(left, right)
        when '#'
          if left.nil?
            Arel::Nodes::UnaryOperation.new(:'#', right)
          else
            Arel::Nodes::BitwiseXor.new(left, right)
          end
        when '~'
          if left.nil?
            Arel::Nodes::BitwiseNot.new(right)
          else
            Arel::Nodes::Regexp.new(left, right, true)
          end
        when '<<'
          Arel::Nodes::BitwiseShiftLeft.new(left, right)
        when '>>'
          Arel::Nodes::BitwiseShiftRight.new(left, right)

        # https://www.postgresql.org/docs/9.0/functions-comparison.html
        when '<'
          Arel::Nodes::LessThan.new(left, right)
        when '>'
          Arel::Nodes::GreaterThan.new(left, right)
        when '<='
          Arel::Nodes::LessThanOrEqual.new(left, right)
        when '>='
          Arel::Nodes::GreaterThanOrEqual.new(left, right)
        when '='
          Arel::Nodes::Equality.new(left, right)
        when '<>'
          Arel::Nodes::NotEqual.new(left, right)

        # https://www.postgresql.org/docs/9.1/functions-array.html
        when '@>'
          Arel::Nodes::Contains.new(left, right)
        when '<@'
          Arel::Nodes::ContainedBy.new(left, right)
        when '&&'
          Arel::Nodes::Overlap.new(left, right)
        when '||'
          Arel::Nodes::Concat.new(left, right)

        # https://www.postgresql.org/docs/9.3/functions-net.html
        when '<<='
          Arel::Nodes::ContainedWithinEquals.new(left, right)
        when '>>='
          Arel::Nodes::ContainsEquals.new(left, right)

        # https://www.postgresql.org/docs/9.4/functions-json.html
        when '->'
          Arel::Nodes::JsonGetObject.new(left, right)
        when '->>'
          Arel::Nodes::JsonGetField.new(left, right)
        when '#>'
          Arel::Nodes::JsonPathGetObject.new(left, right)
        when '#>>'
          Arel::Nodes::JsonPathGetField.new(left, right)

        # https://www.postgresql.org/docs/9.4/functions-json.html#FUNCTIONS-JSONB-OP-TABLE
        when '?'
          Arel::Nodes::JsonbKeyExists.new(left, right)
        when '?|'
          if left.nil?
            Arel::Nodes::UnaryOperation.new(:'?|', right)
          else
            Arel::Nodes::JsonbAnyKeyExists.new(left, right)
          end
        when '?&'
          Arel::Nodes::JsonbAllKeyExists.new(left, right)

        # https://www.postgresql.org/docs/9.3/functions-matching.html#FUNCTIONS-POSIX-TABLE
        when '~*'
          Arel::Nodes::Regexp.new(left, right, false)
        when '!~'
          Arel::Nodes::NotRegexp.new(left, right, true)
        when '!~*'
          Arel::Nodes::NotRegexp.new(left, right, false)

        else
          if left.nil?
            Arel::Nodes::UnaryOperation.new(operator, right)
          else
            Arel::Nodes::InfixOperation.new(operator, left, right)
          end
        end
      end

      def visit(attribute, context = nil)
        return attribute.map { |attr| visit(attr, context) } if
          attribute.is_a?(Google::Protobuf::RepeatedField) || attribute.is_a?(Array)

        dispatch_method = "visit_#{attribute.class.name.demodulize}"

        if context.present?
          method = method(dispatch_method)
          if method.parameters.include?(%i[opt context]) ||
             method.parameters.include?(%i[req context])
            send dispatch_method, attribute, context
          else
            send dispatch_method, attribute
          end
        else
          send dispatch_method, attribute
        end
      end

      def generate_boolean_expression(args, boolean_class)
        chain = boolean_class.new(nil, nil)

        args.each_with_index.reduce(chain) do |c, (arg, index)|
          if args.length - 1 == index
            c.right = arg
            c
          else
            new_chain = boolean_class.new(arg, nil)
            c.right = new_chain
            new_chain
          end
        end

        chain.right
      end

      def generate_sources(clause)
        froms = []
        join_sources = []

        if (from_clauses = clause)
          results = visit(from_clauses).flatten

          results.each do |result|
            case result
            when Arel::Table
              froms << result
            else
              join_sources << result
            end
          end
        end

        if froms.empty?
          [nil, join_sources]
        else
          [froms, join_sources]
        end
      end

      def generate_sublink(sub_link_type, subselect, testexpr, operator)
        case sub_link_type
        when :EXISTS_SUBLINK
          Arel::Nodes::Exists.new subselect

        when :ALL_SUBLINK
          generate_operator(testexpr, Arel::Nodes::All.new(subselect), operator)

        when :ANY_SUBLINK
          if operator.nil?
            Arel::Nodes::In.new(testexpr, subselect)
          else
            generate_operator(testexpr, Arel::Nodes::Any.new(subselect), operator)
          end

        when :ROWCOMPARE_SUBLINK
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/42'

        when :EXPR_SUBLINK
          Arel::Nodes::Grouping.new(subselect)

        when :MULTIEXPR_SUBLINK
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/43'

        when :ARRAY_SUBLINK
          Arel::Nodes::ArraySubselect.new(subselect)

        when :CTE_SUBLINK
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/44'

        else
          boom "Unknown sublinktype: #{type}"
        end
      end

      def maybe_add_grouping(node)
        case node
        when Arel::Nodes::Binary
          Arel::Nodes::Grouping.new(node)
        else
          node
        end
      end

      def boom(message, backtrace = nil)
        new_message = <<~STRING
          SQL: #{sql}
          BINDS: #{binds}
          message: #{message}
        STRING

        raise(Arel::SqlToArel::Error, new_message, backtrace) if backtrace

        raise Arel::SqlToArel::Error, new_message
      end
    end
  end
end

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Naming/MethodName
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/AbcSize
