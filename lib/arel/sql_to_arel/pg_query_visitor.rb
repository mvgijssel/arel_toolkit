# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Naming/MethodName
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ParameterLists

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

        Result.new visit(object, :top)
      rescue ::PgQuery::ParseError => e
        new_error = ::PgQuery::ParseError.new(e.message, __FILE__, __LINE__, -1)
        raise new_error, e.message, e.backtrace
      rescue ::StandardError => e
        raise e.class, e.message, e.backtrace if e.is_a?(Arel::SqlToArel::Error)

        boom e.message, e.backtrace
      end

      private

      def visit_A_ArrayExpr(elements:)
        Arel::Nodes::Array.new visit(elements)
      end

      def visit_A_Const(val:)
        visit(val, :const)
      end

      def visit_A_Expr(kind:, lexpr: nil, rexpr: nil, name:)
        case kind
        when PgQuery::AEXPR_OP
          left = visit(lexpr) if lexpr
          right = visit(rexpr) if rexpr
          operator = visit(name[0], :operator)
          generate_operator(left, right, operator)
        when PgQuery::AEXPR_OP_ANY
          left = visit(lexpr)
          right = visit(rexpr)
          right = Arel::Nodes::Any.new right
          operator = visit(name[0], :operator)
          generate_operator(left, right, operator)
        when PgQuery::AEXPR_OP_ALL
          left = visit(lexpr)
          right = visit(rexpr)
          right = Arel::Nodes::All.new right
          operator = visit(name[0], :operator)
          generate_operator(left, right, operator)
        when PgQuery::AEXPR_DISTINCT
          left = visit(lexpr)
          right = visit(rexpr)
          Arel::Nodes::DistinctFrom.new(left, right)
        when PgQuery::AEXPR_NOT_DISTINCT
          left = visit(lexpr)
          right = visit(rexpr)
          Arel::Nodes::NotDistinctFrom.new(left, right)
        when PgQuery::AEXPR_NULLIF
          left = visit(lexpr)
          right = visit(rexpr)
          Arel::Nodes::NullIf.new(left, right)
        when PgQuery::AEXPR_OF
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/34'
        when PgQuery::AEXPR_IN
          left = visit(lexpr)
          right = visit(rexpr)
          operator = visit(name[0], :operator)

          operator == '<>' ? Arel::Nodes::NotIn.new(left, right) : Arel::Nodes::In.new(left, right)
        when PgQuery::AEXPR_LIKE
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          escape = nil

          if right.is_a?(Array)
            boom "Don't know how to handle length `#{right.length}`" if right.length != 2

            right, escape = right
          end

          operator = visit(name[0], :operator)

          if operator == '~~'
            Arel::Nodes::Matches.new(left, right, escape, true)
          else
            Arel::Nodes::DoesNotMatch.new(left, right, escape, true)
          end
        when PgQuery::AEXPR_ILIKE
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          escape = nil

          if right.is_a?(Array)
            boom "Don't know how to handle length `#{right.length}`" if right.length != 2

            right, escape = right
          end

          operator = visit(name[0], :operator)

          if operator == '~~*'
            Arel::Nodes::Matches.new(left, right, escape, false)
          else
            Arel::Nodes::DoesNotMatch.new(left, right, escape, false)
          end
        when PgQuery::AEXPR_SIMILAR
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          escape = nil

          if right.is_a?(Array)
            boom "Don't know how to handle length `#{right.length}`" if right.length != 2

            right, escape = right
          end

          escape = nil if escape == 'NULL'
          operator = visit(name[0], :operator)

          if operator == '~'
            Arel::Nodes::Similar.new(left, right, escape)
          else
            Arel::Nodes::NotSimilar.new(left, right, escape)
          end
        when PgQuery::AEXPR_BETWEEN
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          Arel::Nodes::Between.new left, Arel::Nodes::And.new(right)
        when PgQuery::AEXPR_NOT_BETWEEN
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          Arel::Nodes::NotBetween.new left, Arel::Nodes::And.new(right)
        when PgQuery::AEXPR_BETWEEN_SYM
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          Arel::Nodes::BetweenSymmetric.new left, Arel::Nodes::And.new(right)
        when PgQuery::AEXPR_NOT_BETWEEN_SYM
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          Arel::Nodes::NotBetweenSymmetric.new left, Arel::Nodes::And.new(right)
        when PgQuery::AEXPR_PAREN
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/35'
        else
          boom "Unknown Expr type `#{kind}`"
        end
      end

      def visit_A_Indices(context, uidx:)
        visit uidx, context
      end

      def visit_A_Indirection(arg:, indirection:)
        Arel::Nodes::Indirection.new(visit(arg), visit(indirection, :operator))
      end

      def visit_A_Star
        Arel.star
      end

      def visit_Alias(aliasname:)
        Arel.sql visit_String(nil, str: aliasname)
      end

      def visit_BitString(str:)
        Arel::Nodes::BitString.new(str)
      end

      def visit_BoolExpr(context = false, args:, boolop:)
        args = visit(args, context || true)

        result =
          case boolop
          when PgQuery::BOOL_EXPR_AND
            Arel::Nodes::And.new(args)
          when PgQuery::BOOL_EXPR_OR
            generate_boolean_expression(args, Arel::Nodes::Or)
          when PgQuery::BOOL_EXPR_NOT
            Arel::Nodes::Not.new(args)
          else
            boom "? Boolop -> #{boolop}"
          end

        context ? Arel::Nodes::Grouping.new(result) : result
      end

      def visit_BooleanTest(arg:, booltesttype:)
        arg = visit(arg)

        case booltesttype
        when PgQuery::BOOLEAN_TEST_TRUE
          Arel::Nodes::Equality.new(arg, Arel::Nodes::True.new)
        when PgQuery::BOOLEAN_TEST_NOT_TRUE
          Arel::Nodes::NotEqual.new(arg, Arel::Nodes::True.new)
        when PgQuery::BOOLEAN_TEST_FALSE
          Arel::Nodes::Equality.new(arg, Arel::Nodes::False.new)
        when PgQuery::BOOLEAN_TEST_NOT_FALSE
          Arel::Nodes::NotEqual.new(arg, Arel::Nodes::False.new)
        when PgQuery::BOOLEAN_TEST_UNKNOWN
          Arel::Nodes::Equality.new(arg, Arel::Nodes::Unknown.new)
        when PgQuery::BOOLEAN_TEST_NOT_UNKNOWN
          Arel::Nodes::NotEqual.new(arg, Arel::Nodes::Unknown.new)
        else
          boom '?'
        end
      end

      def visit_CaseExpr(arg: nil, args:, defresult: nil)
        Arel::Nodes::Case.new.tap do |kees|
          kees.case = visit(arg) if arg

          kees.conditions = visit args

          if defresult
            default_result = visit(defresult, :sql)

            kees.default = Arel::Nodes::Else.new default_result
          end
        end
      end

      def visit_CaseWhen(expr:, result:)
        expr = visit(expr)
        result = visit(result)

        Arel::Nodes::When.new(expr, result)
      end

      def visit_CoalesceExpr(args:)
        args = visit(args)

        Arel::Nodes::Coalesce.new args
      end

      def visit_ColumnRef(fields:)
        fields = fields.reverse
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

      def visit_CommonTableExpr(ctename:, ctequery:)
        cte_table = Arel::Table.new(ctename)
        cte_definition = visit(ctequery)
        Arel::Nodes::As.new(cte_table, Arel::Nodes::Grouping.new(cte_definition))
      end

      def visit_CurrentOfExpr(cursor_name:)
        Arel::Nodes::CurrentOfExpression.new(cursor_name)
      end

      def visit_DefElem(defname:, arg:, defaction:)
        case defname
        when 'savepoint_name'
          visit(arg)
        else
          boom "Unknown defname `#{defname}` with defaction `#{defaction}`"
        end
      end

      def visit_DeleteStmt(
        relation:, using_clause: nil, where_clause: nil, returning_list: [], with_clause: nil
      )
        relation = visit(relation)

        delete_manager = Arel::DeleteManager.new
        delete_statement = delete_manager.ast
        delete_statement.relation = relation
        delete_statement.using = visit(using_clause) if using_clause
        delete_statement.wheres = where_clause ? [visit(where_clause)] : []
        delete_statement.with = visit(with_clause) if with_clause
        delete_statement.returning = visit(returning_list, :select)
        delete_manager
      end

      def visit_Float(str:)
        Arel::Nodes::SqlLiteral.new str
      end

      # https://github.com/postgres/postgres/blob/REL_10_1/src/include/nodes/parsenodes.h
      def visit_FuncCall(
        funcname:,
        args: nil,
        agg_order: nil,
        agg_filter: nil,
        agg_within_group: nil,
        agg_star: nil,
        agg_distinct: nil,
        func_variadic: nil,
        over: nil
      )
        args =
          if args
            visit args
          elsif agg_star
            [Arel.star]
          else
            []
          end

        function_names = visit(funcname, :operator)

        func =
          case function_names
          when %w[sum]
            Arel::Nodes::Sum.new args
          when %w[count]
            Arel::Nodes::Count.new args
          when %w[max]
            Arel::Nodes::Max.new args
          when %w[min]
            Arel::Nodes::Min.new args
          when %w[avg]
            Arel::Nodes::Avg.new args
          when [PG_CATALOG, 'like_escape']
            args
          when [PG_CATALOG, 'similar_escape']
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

        func.distinct = (agg_distinct.nil? ? false : true) unless func.is_a?(::Array)
        func.orders = (agg_order ? visit(agg_order) : []) unless func.is_a?(::Array)
        func.filter = (agg_filter ? visit(agg_filter) : nil) unless func.is_a?(::Array)
        func.within_group = agg_within_group unless func.is_a?(::Array)
        func.variardic = func_variadic unless func.is_a?(::Array)

        over ? Arel::Nodes::Over.new(func, visit(over)) : func
      end

      def visit_InferClause(conname: nil, index_elems: nil)
        left = Arel.sql(conname) if conname
        right = visit(index_elems) if index_elems
        Arel::Nodes::Infer.new left, right
      end

      def visit_IndexElem(name:, ordering:, nulls_ordering:)
        boom "Unknown ordering `#{ordering}`" unless ordering.zero?
        boom "Unknown nulls ordering `#{ordering}`" unless nulls_ordering.zero?

        Arel.sql visit_String(str: name)
      end

      def visit_InsertStmt(
        relation:,
        cols: [],
        select_stmt: nil,
        on_conflict_clause: nil,
        with_clause: nil,
        returning_list: [],
        override:
      )
        relation = visit(relation)
        cols = visit(cols, :insert).map { |col| Arel::Attribute.new(relation, col) }
        select_stmt = visit(select_stmt) if select_stmt

        insert_manager = Arel::InsertManager.new
        insert_statement = insert_manager.ast
        insert_statement.relation = relation
        insert_statement.columns = cols
        insert_statement.override = override
        insert_statement.with = visit(with_clause) if with_clause

        if select_stmt
          insert_statement.values = select_stmt.values_lists if select_stmt
        else
          insert_statement.values = Arel::Nodes::DefaultValues.new
        end

        insert_statement.returning = visit(returning_list, :select)
        insert_statement.conflict = visit(on_conflict_clause) if on_conflict_clause
        insert_manager
      end

      def visit_Integer(ival:)
        ival
      end

      def visit_IntoClause(rel:, on_commit:)
        raise "Unknown on_commit `#{on_commit}`" unless on_commit.zero?

        Arel::Nodes::Into.new(visit(rel))
      end

      def visit_JoinExpr(jointype:, is_natural: nil, larg:, rarg:, quals: nil)
        join_class =
          case jointype
          when 0
            if is_natural
              Arel::Nodes::NaturalJoin
            elsif quals.nil?
              Arel::Nodes::CrossJoin
            else
              Arel::Nodes::InnerJoin
            end
          when 1
            Arel::Nodes::OuterJoin
          when 2
            Arel::Nodes::FullOuterJoin
          when 3
            Arel::Nodes::RightOuterJoin
          end

        larg = visit(larg)
        rarg = visit(rarg)

        quals = Arel::Nodes::On.new visit(quals) if quals

        join = join_class.new(rarg, quals)

        larg.is_a?(Array) ? larg.concat([join]) : [larg, join]
      end

      def visit_LockingClause(strength:, wait_policy:)
        strength_clause =
          {
            1 => 'FOR KEY SHARE', 2 => 'FOR SHARE', 3 => 'FOR NO KEY UPDATE', 4 => 'FOR UPDATE'
          }.fetch(strength)
        wait_policy_clause = { 0 => '', 1 => ' SKIP LOCKED', 2 => ' NOWAIT' }.fetch(wait_policy)

        Arel::Nodes::Lock.new Arel.sql("#{strength_clause}#{wait_policy_clause}")
      end

      def visit_MinMaxExpr(op:, args:)
        case op
        when 0
          Arel::Nodes::Greatest.new visit(args)
        when 1
          Arel::Nodes::Least.new visit(args)
        else
          boom "Unknown Op -> #{op}"
        end
      end

      def visit_NamedArgExpr(arg:, name:, argnumber:)
        arg = visit(arg)
        boom '' unless argnumber == -1

        Arel::Nodes::NamedArgument.new(name, arg)
      end

      def visit_Null(**_)
        Arel.sql 'NULL'
      end

      def visit_NullTest(arg:, nulltesttype:)
        arg = visit(arg)

        case nulltesttype
        when PgQuery::CONSTR_TYPE_NULL
          Arel::Nodes::Equality.new(arg, nil)
        when PgQuery::CONSTR_TYPE_NOTNULL
          Arel::Nodes::NotEqual.new(arg, nil)
        end
      end

      def visit_OnConflictClause(action:, infer: nil, target_list: nil, where_clause: nil)
        conflict = Arel::Nodes::Conflict.new
        conflict.action = action
        conflict.infer = visit(infer) if infer
        conflict.values = target_list ? visit(target_list, :update) : []
        conflict.wheres = where_clause ? [visit(where_clause)] : []
        conflict
      end

      def visit_ParamRef(number: nil)
        value = (binds[number - 1] unless binds.empty?)

        Arel::Nodes::BindParam.new(value)
      end

      def visit_RangeFunction(
        is_rowsfrom: nil, functions:, lateral: false, ordinality: false, aliaz: nil
      )
        functions =
          functions.map do |function_array|
            function, empty_value = function_array
            boom 'https://github.com/mvgijssel/arel_toolkit/issues/37' unless empty_value.nil?

            visit(function)
          end

        node = Arel::Nodes::RangeFunction.new functions, is_rowsfrom: is_rowsfrom
        node = lateral ? Arel::Nodes::Lateral.new(node) : node
        node = ordinality ? Arel::Nodes::WithOrdinality.new(node) : node
        aliaz.nil? ? node : Arel::Nodes::As.new(node, visit(aliaz))
      end

      def visit_RangeSubselect(aliaz:, subquery:, lateral: false)
        aliaz = visit(aliaz)
        subquery = visit(subquery)
        node = Arel::Nodes::As.new(Arel::Nodes::Grouping.new(subquery), aliaz)
        lateral ? Arel::Nodes::Lateral.new(node) : node
      end

      def visit_RangeVar(aliaz: nil, relname:, inh: false, relpersistence:, schemaname: nil)
        Arel::Table.new(
          relname,
          as: (visit(aliaz) if aliaz),
          only: !inh,
          relpersistence: relpersistence,
          schema_name: schemaname
        )
      end

      def visit_RawStmt(context, **args)
        visit(args.fetch(:stmt), context)
      end

      def visit_ResTarget(context, val: nil, name: nil)
        case context
        when :select
          val = visit(val)

          if name
            aliaz = visit_Alias(aliasname: name)
            Arel::Nodes::As.new(val, aliaz)
          else
            val
          end
        when :insert
          name
        when :update
          relation = nil
          column = Arel::Attribute.new(relation, name)
          value = visit(val)

          Nodes::Assignment.new(Nodes::UnqualifiedColumn.new(column), value)
        else
          boom "Unknown context `#{context}`"
        end
      end

      def visit_RowExpr(args:, row_format:)
        Arel::Nodes::Row.new(visit(args), row_format)
      end

      def visit_SelectStmt(
        context = nil,
        from_clause: nil,
        limit_count: nil,
        target_list: nil,
        sort_clause: nil,
        where_clause: nil,
        limit_offset: nil,
        distinct_clause: nil,
        group_clause: nil,
        having_clause: nil,
        with_clause: nil,
        locking_clause: nil,
        op:,
        window_clause: nil,
        values_lists: nil,
        into_clause: nil,
        all: nil,
        larg: nil,
        rarg: nil
      )
        select_manager = Arel::SelectManager.new
        select_core = select_manager.ast.cores.last
        select_statement = select_manager.ast

        froms, join_sources = generate_sources(from_clause)

        if froms
          froms = froms.first if froms.length == 1
          select_core.froms = froms
        end

        select_core.from = froms if froms
        select_core.source.right = join_sources

        select_core.projections = visit(target_list, :select) if target_list

        if where_clause
          where_clause = visit(where_clause)
          where_clause =
            if where_clause.is_a?(Arel::Nodes::And)
              where_clause
            else
              Arel::Nodes::And.new([where_clause])
            end

          select_core.wheres = [where_clause]
        end

        select_core.groups = visit(group_clause) if group_clause
        select_core.havings = [visit(having_clause)] if having_clause
        select_core.windows = visit(window_clause) if window_clause
        select_core.into = visit(into_clause) if into_clause
        select_core.top = ::Arel::Nodes::Top.new visit(limit_count) if limit_count

        if distinct_clause == [nil]
          select_core.set_quantifier = Arel::Nodes::Distinct.new
        elsif distinct_clause.is_a?(Array)
          select_core.set_quantifier = Arel::Nodes::DistinctOn.new(visit(distinct_clause))
        elsif distinct_clause.nil?
          select_core.set_quantifier = nil
        else
          boom "Unknown distinct clause `#{distinct_clause}`"
        end

        select_statement.limit = ::Arel::Nodes::Limit.new visit(limit_count) if limit_count
        select_statement.offset = ::Arel::Nodes::Offset.new visit(limit_offset) if limit_offset
        select_statement.orders = visit(sort_clause.to_a)
        select_statement.with = visit(with_clause) if with_clause
        select_statement.lock = visit(locking_clause) if locking_clause
        if values_lists
          values_lists =
            visit(values_lists).map do |values_list|
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

        union =
          case op
          when 0
            nil
          when 1
            if all
              Arel::Nodes::UnionAll.new(visit(larg), visit(rarg))
            else
              Arel::Nodes::Union.new(visit(larg), visit(rarg))
            end
          when 2
            if all
              Arel::Nodes::IntersectAll.new(visit(larg), visit(rarg))
            else
              Arel::Nodes::Intersect.new(visit(larg), visit(rarg))
            end
          when 3
            if all
              Arel::Nodes::ExceptAll.new(visit(larg), visit(rarg))
            else
              Arel::Nodes::Except.new(visit(larg), visit(rarg))
            end
          else
            # https://www.postgresql.org/docs/10/queries-union.html
            boom "Unknown combining queries op `#{op}`"
          end

        unless union.nil?
          select_statement.cores = []
          select_statement.union = union
        end

        context == :top ? select_manager : select_statement
      end

      def visit_SetToDefault(_args)
        Arel::Nodes::SetToDefault.new
      end

      def visit_SortBy(node:, sortby_dir:, sortby_nulls:)
        result = visit(node)
        case sortby_dir
        when 1
          Arel::Nodes::Ascending.new(result, sortby_nulls)
        when 2
          Arel::Nodes::Descending.new(result, sortby_nulls)
        else
          result
        end
      end

      def visit_SQLValueFunction(op:, typmod:)
        [
          -> { Arel::Nodes::CurrentDate.new },
          -> { Arel::Nodes::CurrentTime.new },
          -> { Arel::Nodes::CurrentTime.new(precision: typmod) },
          -> { Arel::Nodes::CurrentTimestamp.new },
          -> { Arel::Nodes::CurrentTimestamp.new(precision: typmod) },
          -> { Arel::Nodes::LocalTime.new },
          -> { Arel::Nodes::LocalTime.new(precision: typmod) },
          -> { Arel::Nodes::LocalTimestamp.new },
          -> { Arel::Nodes::LocalTimestamp.new(precision: typmod) },
          -> { Arel::Nodes::CurrentRole.new },
          -> { Arel::Nodes::CurrentUser.new },
          -> { Arel::Nodes::User.new },
          -> { Arel::Nodes::SessionUser.new },
          -> { Arel::Nodes::CurrentCatalog.new },
          -> { Arel::Nodes::CurrentSchema.new }
        ][
          op
        ]
          .call
      end

      def visit_String(context = nil, str:)
        case context
        when :operator
          str
        when :const
          Arel::Nodes.build_quoted str
        else
          "\"#{str}\""
        end
      end

      def visit_SubLink(subselect:, sub_link_type:, testexpr: nil, oper_name: nil)
        subselect = visit(subselect)
        testexpr = visit(testexpr) if testexpr
        operator =
          if oper_name
            operator = visit(oper_name, :operator)
            boom 'https://github.com/mvgijssel/arel_toolkit/issues/39' if operator.length > 1

            operator.first
          end

        generate_sublink(sub_link_type, subselect, testexpr, operator)
      end

      def visit_TransactionStmt(kind:, options: nil)
        Arel::Nodes::Transaction.new(kind, (visit(options) if options))
      end

      def visit_TypeCast(arg:, type_name:)
        arg = visit(arg)
        type_name = visit(type_name)

        Arel::Nodes::TypeCast.new(maybe_add_grouping(arg), type_name)
      end

      def visit_TypeName(names:, typemod:, array_bounds: [])
        array_bounds = visit(array_bounds)

        names = names.map { |name| visit(name, :operator) }

        names = names.reject { |name| name == PG_CATALOG }

        boom 'https://github.com/mvgijssel/arel_toolkit/issues/40' if typemod != -1
        boom 'https://github.com/mvgijssel/arel_toolkit/issues/41' if names.length > 1
        if array_bounds != [] && array_bounds != [-1]
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/86'
        end

        type_name = names.first
        type_name =
          case type_name
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

        type_name << '[]' if array_bounds == [-1]
        type_name
      end

      def visit_UpdateStmt(
        relation:,
        target_list:,
        where_clause: nil,
        from_clause: [],
        returning_list: [],
        with_clause: nil
      )
        relation = visit(relation)
        target_list = visit(target_list, :update)

        update_manager = Arel::UpdateManager.new
        update_statement = update_manager.ast
        update_statement.relation = relation
        update_statement.froms = visit(from_clause)
        update_statement.values = target_list
        update_statement.wheres = where_clause ? [visit(where_clause)] : []
        update_statement.with = visit(with_clause) if with_clause
        update_statement.returning = visit(returning_list, :select)
        update_manager
      end

      def visit_VariableSetStmt(kind:, name:, args: [], is_local: false)
        Arel::Nodes::VariableSet.new(kind, visit(args), name, is_local)
      end

      def visit_VariableShowStmt(name:)
        Arel::Nodes::VariableShow.new(name)
      end

      def visit_WindowDef(
        partition_clause: [],
        order_clause: [],
        frame_options:,
        name: nil,
        start_offset: nil,
        end_offset: nil
      )
        if name.present? && partition_clause.empty? && order_clause.empty?
          return Arel::Nodes::SqlLiteral.new(name)
        end

        instance = name.nil? ? Arel::Nodes::Window.new : Arel::Nodes::NamedWindow.new(name)
        instance.tap do |window|
          window.orders = visit order_clause
          window.partitions = visit partition_clause

          if frame_options
            window.framing =
              FrameOptions.arel(
                frame_options,
                (visit(start_offset) if start_offset),
                (visit(end_offset) if end_offset)
              )
          end
        end
      end

      def visit_WithClause(ctes:, recursive: false)
        if recursive
          Arel::Nodes::WithRecursive.new visit(ctes)
        else
          Arel::Nodes::With.new visit(ctes)
        end
      end

      def generate_operator(left, right, operator)
        left = maybe_add_grouping(left)
        right = maybe_add_grouping(right)

        case operator
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
        # https://www.postgresql.org/docs/10/functions-math.html
      end

      def visit_DeallocateStmt(name: nil)
        Arel::Nodes::Dealocate.new name
      end

      def visit_PrepareStmt(name:, argtypes: nil, query:)
        Arel::Nodes::Prepare.new name, argtypes && visit(argtypes), visit(query)
      end

      def visit(attribute, context = nil)
        return attribute.map { |attr| visit(attr, context) } if attribute.is_a? Array

        klass, attributes = klass_and_attributes(attribute)
        dispatch_method = "visit_#{klass}"
        method = method(dispatch_method)

        arg_has_context =
          (
            method.parameters.include?(%i[opt context]) ||
              method.parameters.include?(%i[req context])
          ) &&
            context

        args = arg_has_context ? [context] : nil

        if attributes.empty?
          send dispatch_method, *args
        else
          kwargs =
            attributes.transform_keys do |key|
              key.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase.to_sym
            end

          kwargs.delete(:location)

          if (aliaz = kwargs.delete(:alias))
            kwargs[:aliaz] = aliaz
          end

          send dispatch_method, *args, **kwargs
        end
      end

      def klass_and_attributes(object)
        [object.keys.first, object.values.first]
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

        froms.empty? ? [nil, join_sources] : [froms, join_sources]
      end

      def generate_sublink(sub_link_type, subselect, testexpr, operator)
        case sub_link_type
        when PgQuery::SUBLINK_TYPE_EXISTS
          Arel::Nodes::Exists.new subselect
        when PgQuery::SUBLINK_TYPE_ALL
          generate_operator(testexpr, Arel::Nodes::All.new(subselect), operator)
        when PgQuery::SUBLINK_TYPE_ANY
          if operator.nil?
            Arel::Nodes::In.new(testexpr, subselect)
          else
            generate_operator(testexpr, Arel::Nodes::Any.new(subselect), operator)
          end
        when PgQuery::SUBLINK_TYPE_ROWCOMPARE
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/42'
        when PgQuery::SUBLINK_TYPE_EXPR
          Arel::Nodes::Grouping.new(subselect)
        when PgQuery::SUBLINK_TYPE_MULTIEXPR
          boom 'https://github.com/mvgijssel/arel_toolkit/issues/43'
        when PgQuery::SUBLINK_TYPE_ARRAY
          Arel::Nodes::ArraySubselect.new(subselect)
        when PgQuery::SUBLINK_TYPE_CTE
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
# rubocop:enable Naming/UncommunicativeMethodParamName
# rubocop:enable Metrics/ParameterLists
