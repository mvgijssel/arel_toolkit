# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Naming/MethodName
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Naming/UncommunicativeMethodParamName
# rubocop:disable Metrics/ParameterLists

require 'pg_query'
require_relative './frame_options'

module Arel
  module SqlToArel
    class PgQueryVisitor
      PG_CATALOG = 'pg_catalog'.freeze
      MIN_MAX_EXPR = 'MinMaxExpr'.freeze

      attr_reader :object

      def accept(sql)
        tree = PgQuery.parse(sql).tree
        @object = tree.first # TODO: handle multiple entries
        visit object
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
          raise '?'

        when PgQuery::AEXPR_IN
          left = visit(lexpr)
          right = visit(rexpr)
          operator = visit(name[0], :operator)

          if operator == '<>'
            Arel::Nodes::NotIn.new(left, right)
          else
            Arel::Nodes::In.new(left, right)
          end

        when PgQuery::AEXPR_LIKE
          left = visit(lexpr) if lexpr
          right = visit(rexpr)
          escape = nil

          if right.is_a?(Array)
            raise "Don't know how to handle length `#{right.length}`" if right.length != 2

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
            raise "Don't know how to handle length `#{right.length}`" if right.length != 2

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
            raise "Don't know how to handle length `#{right.length}`" if right.length != 2

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
          raise '?'

        else
          raise "Unknown Expr type `#{kind}`"
        end
      end

      def visit_A_Indices(context, uidx:)
        visit uidx, context
      end

      def visit_A_Indirection(arg:, indirection:)
        Arel::Nodes::Indirection.new(visit(arg, :operator), visit(indirection, :operator))
      end

      def visit_A_Star
        Arel.star
      end

      def visit_Alias(aliasname:)
        aliasname
      end

      def visit_BitString(str:)
        Arel::Nodes::BitString.new(str)
      end

      def visit_BoolExpr(context = false, args:, boolop:)
        args = visit(args, context || true)

        result = case boolop
                 when PgQuery::BOOL_EXPR_AND
                   Arel::Nodes::And.new(args)

                 when PgQuery::BOOL_EXPR_OR
                   generate_boolean_expression(args, Arel::Nodes::Or)

                 when PgQuery::BOOL_EXPR_NOT
                   Arel::Nodes::Not.new(args)

                 else
                   raise "? Boolop -> #{boolop}"
                 end

        if context
          Arel::Nodes::Grouping.new(result)
        else
          result
        end
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
          raise '?'
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

      def visit_ColumnRef(context = nil, fields:)
        UnboundColumnReference.new visit(fields, context).join('.')
      end

      def visit_CommonTableExpr(ctename:, ctequery:)
        cte_table = Arel::Table.new(ctename)
        cte_definition = visit(ctequery)
        Arel::Nodes::As.new(cte_table, Arel::Nodes::Grouping.new(cte_definition))
      end

      def visit_CurrentOfExpr(cursor_name:)
        Arel::Nodes::CurrentOfExpression.new(cursor_name)
      end

      def visit_DeleteStmt(
        relation:,
        using_clause: nil,
        where_clause: nil,
        returning_list: [],
        with_clause: nil
      )
        relation = visit(relation)

        delete_statement = Arel::Nodes::DeleteStatement.new
        delete_statement.relation = relation
        delete_statement.using = visit(using_clause) if using_clause
        delete_statement.wheres = where_clause ? [visit(where_clause)] : []
        delete_statement.with = visit(with_clause) if with_clause
        delete_statement.returning = visit(returning_list, :select)

        delete_statement
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
        args = if args
                 visit args
               elsif agg_star
                 [Arel.star]
               else
                 []
               end

        function_names = visit(funcname, :operator)

        func = case function_names
               when ['sum']
                 Arel::Nodes::Sum.new args

               when ['rank']
                 Arel::Nodes::Rank.new args

               when ['count']
                 Arel::Nodes::Count.new args

               when ['generate_series']
                 Arel::Nodes::GenerateSeries.new args

               when ['max']
                 Arel::Nodes::Max.new args

               when ['min']
                 Arel::Nodes::Min.new args

               when ['avg']
                 Arel::Nodes::Avg.new args

               when [PG_CATALOG, 'like_escape']
                 args

               when [PG_CATALOG, 'similar_escape']
                 args

               else
                 raise "Don't know how to handle `#{function_names}`" if function_names.length > 1

                 Arel::Nodes::NamedFunction.new(function_names.first, args)
               end

        func.distinct = (agg_distinct.nil? ? false : true) unless func.is_a?(::Array)
        func.orders = (agg_order ? visit(agg_order) : []) unless func.is_a?(::Array)
        func.filter = (agg_filter ? visit(agg_filter) : nil) unless func.is_a?(::Array)
        func.within_group = agg_within_group unless func.is_a?(::Array)
        func.variardic = func_variadic unless func.is_a?(::Array)

        if over
          Arel::Nodes::Over.new(func, visit(over))
        else
          func
        end
      end

      def visit_InferClause(conname: nil, index_elems: nil)
        infer = Arel::Nodes::Infer.new
        infer.name = Arel.sql(conname) if conname
        infer.indexes = visit(index_elems) if index_elems
        infer
      end

      def visit_IndexElem(name:, ordering:, nulls_ordering:)
        raise "Unknown ordering `#{ordering}`" unless ordering.zero?
        raise "Unknown nulls ordering `#{ordering}`" unless nulls_ordering.zero?

        Arel.sql(name)
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
        cols = visit(cols, :insert).map do |col|
          Arel::Attribute.new(relation, col)
        end
        select_stmt = visit(select_stmt) if select_stmt

        insert_statement = Arel::Nodes::InsertStatement.new
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
        insert_statement.on_conflict = visit(on_conflict_clause) if on_conflict_clause
        insert_statement
      end

      def visit_Integer(ival:)
        ival
      end

      def visit_JoinExpr(jointype:, is_natural: nil, larg:, rarg:, quals: nil)
        join_class = case jointype
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

        if larg.is_a?(Array)
          larg.concat([join])
        else
          [larg, join]
        end
      end

      def visit_LockingClause(strength:, wait_policy:)
        strength_clause = {
          1 => 'FOR KEY SHARE',
          2 => 'FOR SHARE',
          3 => 'FOR NO KEY UPDATE',
          4 => 'FOR UPDATE'
        }.fetch(strength)
        wait_policy_clause = {
          0 => '',
          1 => ' SKIP LOCKED',
          2 => ' NOWAIT'
        }.fetch(wait_policy)

        Arel::Nodes::Lock.new Arel.sql("#{strength_clause}#{wait_policy_clause}")
      end

      def visit_MinMaxExpr(op:, args:)
        case op
        when 0
          Arel::Nodes::Greatest.new visit(args)
        when 1
          Arel::Nodes::Least.new visit(args)
        else
          raise "Unknown Op -> #{op}"
        end
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

      def visit_ParamRef(_args)
        Arel::Nodes::BindParam.new(nil)
      end

      def visit_RangeFunction(is_rowsfrom:, functions:, lateral: false, ordinality: false)
        raise 'i dunno' unless is_rowsfrom

        functions = functions.map do |function_array|
          function, empty_value = function_array
          raise 'i dunno' unless empty_value.nil?

          visit(function)
        end

        node = Arel::Nodes::RangeFunction.new functions
        node = lateral ? Arel::Nodes::Lateral.new(node) : node
        ordinality ? Arel::Nodes::WithOrdinality.new(node) : node
      end

      def visit_RangeSubselect(aliaz:, subquery:, lateral: false)
        aliaz = visit(aliaz)
        subquery = visit(subquery)
        node = Arel::Nodes::TableAlias.new(Arel::Nodes::Grouping.new(subquery), aliaz)
        lateral ? Arel::Nodes::Lateral.new(node) : node
      end

      def visit_RangeVar(aliaz: nil, relname:, inh: false, relpersistence:, schemaname: nil)
        Arel::Table.new(
          relname,
          as: (visit(aliaz) if aliaz),
          only: !inh,
          relpersistence: relpersistence,
          schema_name: schemaname,
        )
      end

      def visit_RawStmt(stmt:)
        visit(stmt)
      end

      def visit_ResTarget(context, val: nil, name: nil)
        case context
        when :select
          val = visit(val)

          if name
            Arel::Nodes::As.new(val, Arel.sql(name))
          else
            val
          end
        when :insert
          name
        when :update
          Arel::Nodes::Equality.new(
            Arel.sql(visit_String(str: name)),
            visit(val),
          )
        else
          raise "Unknown context `#{context}`"
        end
      end

      def visit_RowExpr(args:, row_format:)
        Arel::Nodes::Row.new(visit(args), row_format)
      end

      def visit_SelectStmt(
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
        values_lists: nil
      )

        raise "Unknown op `#{op}`" unless op.zero?

        select_core = Arel::Nodes::SelectCore.new

        froms, join_sources = generate_sources(from_clause)
        select_core.from = froms if froms
        select_core.source.right = join_sources

        select_core.projections = visit(target_list, :select) if target_list
        select_core.wheres = [visit(where_clause)] if where_clause
        select_core.groups = visit(group_clause) if group_clause
        select_core.havings = [visit(having_clause)] if having_clause
        select_core.windows = visit(window_clause) if window_clause

        if distinct_clause == [nil]
          select_core.set_quantifier = Arel::Nodes::Distinct.new
        elsif distinct_clause.is_a?(Array)
          select_core.set_quantifier = Arel::Nodes::DistinctOn.new(visit(distinct_clause))
        elsif distinct_clause.nil?
          select_core.set_quantifier = nil
        else
          raise "Unknown distinct clause `#{distinct_clause}`"
        end

        select_statement = Arel::Nodes::SelectStatement.new [select_core]
        select_statement.limit = ::Arel::Nodes::Limit.new visit(limit_count) if limit_count
        select_statement.offset = ::Arel::Nodes::Offset.new visit(limit_offset) if limit_offset
        select_statement.orders = visit(sort_clause.to_a)
        select_statement.with = visit(with_clause) if with_clause
        select_statement.lock = visit(locking_clause) if locking_clause
        if values_lists
          values_lists = visit(values_lists).map do |values_list|
            values_list.map do |value|
              case value
              when String
                value
              when Integer
                Arel.sql(value.to_s)
              when Arel::Nodes::TypeCast
                Arel.sql(value.to_sql)
              when Arel::Nodes::BindParam
                value
              else
                raise "Unknown value `#{value}`"
              end
            end
          end
          select_statement.values_lists = Arel::Nodes::ValuesList.new(values_lists)
        end
        select_statement
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
          -> { Arel::Nodes::CurrentSchema.new },
        ][op].call
      end

      def visit_String(context = nil, str:)
        case context
        when :operator
          str
        when :const
          Arel.sql "'#{str}'"
        else
          "\"#{str}\""
        end
      end

      def visit_SubLink(subselect:, sub_link_type:, testexpr: nil, oper_name: nil)
        subselect = visit(subselect)
        testexpr = visit(testexpr) if testexpr
        operator = if oper_name
                     operator = visit(oper_name, :operator)
                     raise "dunno how to handle `#{operator.length}`" if operator.length > 1

                     operator.first
                   end

        generate_sublink(sub_link_type, subselect, testexpr, operator)
      end

      def visit_TypeCast(arg:, type_name:)
        arg = visit(arg)
        type_name = visit(type_name)

        Arel::Nodes::TypeCast.new(arg, type_name)
      end

      def visit_TypeName(names:, typemod:)
        names = names.map do |name|
          visit(name, :operator)
        end

        names = names.reject { |name| name == PG_CATALOG }

        raise "Don't know how to handle typemod `#{typemod}`" if typemod != -1
        raise "Don't know how to handle `#{names.length}` names" if names.length > 1

        names.first
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

        update_statement = Arel::Nodes::UpdateStatement.new
        update_statement.relation = relation
        update_statement.froms = visit(from_clause)
        update_statement.values = target_list
        update_statement.wheres = where_clause ? [visit(where_clause)] : []
        update_statement.with = visit(with_clause) if with_clause
        update_statement.returning = visit(returning_list, :select)

        update_statement
      end

      def visit_WindowDef(
        partition_clause: [],
        order_clause: [],
        frame_options:,
        name: nil,
        start_offset: nil,
        end_offset: nil
      )
        instance = name.nil? ? Arel::Nodes::Window.new : Arel::Nodes::NamedWindow.new(name)

        instance.tap do |window|
          window.orders = visit order_clause
          window.partitions = visit partition_clause

          if frame_options
            window.framing = FrameOptions.arel(
              frame_options,
              (visit(start_offset) if start_offset),
              (visit(end_offset) if end_offset),
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
        case operator

        # https://www.postgresql.org/docs/10/functions-math.html
        when '+'
          Arel::Nodes::Addition.new(left, right)
        when '-'
          Arel::Nodes::Subtraction.new(left, right)
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
          Arel::Nodes::BitwiseXor.new(left, right)
        when '~'
          Arel::Nodes::BitwiseNot.new(right)
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

        else
          raise "Unknown operator `#{operator}`"
        end
      end

      def visit(attribute, context = nil)
        return attribute.map { |attr| visit(attr, context) } if attribute.is_a? Array

        klass, attributes = klass_and_attributes(attribute)
        dispatch_method = "visit_#{klass}"
        method = method(dispatch_method)

        arg_has_context = (method.parameters.include?(%i[opt context]) ||
          method.parameters.include?(%i[req context])) && context

        args = arg_has_context ? [context] : nil

        if attributes.empty?
          send dispatch_method, *args
        else
          kwargs = attributes.transform_keys do |key|
            key
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .downcase
              .to_sym
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

        if froms.empty?
          [nil, join_sources]
        else
          [froms, join_sources]
        end
      end

      def generate_sublink(sub_link_type, subselect, testexpr, operator)
        case sub_link_type
        when PgQuery::SUBLINK_TYPE_EXISTS
          Arel::Nodes::Exists.new subselect

        when PgQuery::SUBLINK_TYPE_ALL
          generate_operator(testexpr, Arel::Nodes::All.new(subselect), operator)

        when PgQuery::SUBLINK_TYPE_ANY
          generate_operator(testexpr, Arel::Nodes::Any.new(subselect), operator)

        when PgQuery::SUBLINK_TYPE_ROWCOMPARE
          raise '?'

        when PgQuery::SUBLINK_TYPE_EXPR
          Arel::Nodes::Grouping.new(subselect)

        when PgQuery::SUBLINK_TYPE_MULTIEXPR
          raise '?'

        when PgQuery::SUBLINK_TYPE_ARRAY
          Arel::Nodes::ArraySubselect.new(subselect)

        when PgQuery::SUBLINK_TYPE_CTE
          raise '?'

        else
          raise "Unknown sublinktype: #{type}"
        end
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
