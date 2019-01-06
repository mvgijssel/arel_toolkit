require 'to_arel/version'
require 'arel'
require_relative './more_arel_extensions'
require 'pg_query'

def symbolize_keys(hash)
  Hash[hash.map { |k, v| [k.to_sym, v] }]
end

# rubocop:disable Naming/MethodName
module ToArel
  PG_CATALOG = 'pg_catalog'
  BOOLEAN = 'boolean'

  class UnboundColumnReference < ::Arel::Nodes::SqlLiteral; end

  class Visitor
    attr_reader :object

    def accept(object)
      @object = object
      visit object
    end

    private

    def visit(attribute, context = nil)
      klass, attributes = klass_and_attributes(attribute)
      dispatch_method = "visit_#{klass}"
      method = method(dispatch_method)

      args = if method.parameters.include?([:opt, :context]) && context
               [context]
             end

      if attributes.empty?
        send dispatch_method, *args
      else
        kwargs = symbolize_keys(attributes)
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

    def visit_String(context = nil, str:)
      case context
      when :operator
        str
      when :const
        "'#{str}'"
      else
        "\"#{str}\""
      end
    end

    def visit_Integer(ival:)
      # Arel::Attributes::Integer.new attributes[:ival]
      ival
    end

    def visit_ColumnRef(fields:)
      UnboundColumnReference.new(
        fields.map do |field|
          visit(field)
        end.join('.')
      )
    end

    def visit_ResTarget(val:, name: nil)
      val = visit(val)

      if name
        Arel::Nodes::As.new(val, Arel.sql(name))
      else
        val
      end
    end

    def visit_SubLink(subselect:, subLinkType:)
      # SUBLINK_TYPE_EXISTS = 0     # EXISTS(SELECT ...)
      # SUBLINK_TYPE_ALL = 1        # (lefthand) op ALL (SELECT ...)
      # SUBLINK_TYPE_ANY = 2        # (lefthand) op ANY (SELECT ...)
      # SUBLINK_TYPE_ROWCOMPARE = 3 # (lefthand) op (SELECT ...)
      # SUBLINK_TYPE_EXPR = 4       # (SELECT with single targetlist item ...)
      # SUBLINK_TYPE_MULTIEXPR = 5  # (SELECT with multiple targetlist items ...)
      # SUBLINK_TYPE_ARRAY = 6      # ARRAY(SELECT with single targetlist item ...)
      # SUBLINK_TYPE_CTE = 7        # WITH query (never actually part of an expression), for SubPlans only

      subselect = if subselect
                    visit(subselect)
                  end

      case subLinkType
      when PgQuery::SUBLINK_TYPE_EXPR
        visit(subselect)

      when PgQuery::SUBLINK_TYPE_ANY
        raise '2'

      when PgQuery::SUBLINK_TYPE_EXISTS
        Arel::Nodes::Exists.new subselect

      else
        raise "Unknown sublinktype: #{type}"
      end
    end

    def visit_Alias(aliasname:)
      aliasname
    end

    def visit_RangeVar(aliaz: nil, relname:, inh:, relpersistence:)
      Arel::Table.new relname, as: (visit(aliaz) if aliaz)
    end

    def visit_A_Expr(kind:, lexpr:, rexpr:, name:)
      case kind
      when PgQuery::AEXPR_OP
        left = visit(lexpr)
        right = visit(rexpr)

        operator = visit(name[0], :operator)
        generate_comparison(left, right, operator)

      when PgQuery::AEXPR_OP_ANY
        left = visit(lexpr)

        right = visit(rexpr)
        right = Arel::Nodes::NamedFunction.new('ANY', [Arel.sql(right)])

        operator = visit(name[0], :operator)
        generate_comparison(left, right, operator)

      when PgQuery::AEXPR_IN
        left = visit(lexpr)
        left = left.is_a?(String) ? Arel.sql(left) : left

        right = rexpr.map do |expr|
          result = visit(expr)
          result.is_a?(String) ? Arel.sql(result) : result
        end

        operator = visit(name[0], :operator)
        if operator == '<>'
          Arel::Nodes::NotIn.new(left, right)
        else
          Arel::Nodes::In.new(left, right)
        end

      when PgQuery::CONSTR_TYPE_FOREIGN
        raise '?'

      when PgQuery::AEXPR_BETWEEN
        left = visit(lexpr)

        right = rexpr.map do |expr|
          result = visit(expr)
          result.is_a?(String) ? Arel.sql(result) : result
        end

        Arel::Nodes::Between.new left, Arel::Nodes::And.new(right)

      when PgQuery::AEXPR_NOT_BETWEEN,
           PgQuery::AEXPR_BETWEEN_SYM,
           PgQuery::AEXPR_NOT_BETWEEN_SYM
        raise '?'

      when PgQuery::AEXPR_NULLIF
        raise '?'

      else
        raise '?'
      end
    end

    def visit_A_Const(val:)
      visit(val, :const)
    end

    def visit_RangeSubselect(aliaz:, subquery:)
      aliaz = visit(aliaz)
      subquery = visit(subquery)

      Arel::Nodes::TableAlias.new(Arel::Nodes::Grouping.new(subquery), aliaz)
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

    def visit_CaseWhen(expr:, result:)
      expr = visit(expr)
      result = visit(result)

      # TODO: Let's figure out if this is the way to go
      result = case result
               when Integer
                 result
               else
                 Arel.sql(result)
               end

      Arel::Nodes::When.new(expr, result)
    end

    def visit_CaseExpr(arg: nil, args:, defresult: nil)
      Arel::Nodes::Case.new.tap do |kees|
        kees.case = visit(arg) if arg

        kees.conditions = args.map { |a| visit(a) }

        if defresult
          default_result = visit(defresult)
          default_result = case default_result
                           when Integer
                             default_result
                           else
                             Arel.sql(default_result)
                           end

          kees.default = Arel::Nodes::Else.new default_result
        end
      end
    end

    def visit_SQLValueFunction(op:, typmod:)
      [
        ->(_) { Arel::Nodes::CurrentDate.new },
        ->(_) { Arel::Nodes::CurrentTime.new },
        ->(typmod) { Arel::Nodes::CurrentTime.new(precision: typmod) },
        ->(_) { Arel::Nodes::CurrentTimestamp.new },
        ->(_typmod) { raise '?' }, # current_timestamp, # with precision
        ->(_typmod) { raise '?' }, # localtime,
        ->(_typmod) { raise '?' }, # localtime, # with precision
        ->(_typmod) { raise '?' }, # localtimestamp,
        ->(_typmod) { raise '?' }, # localtimestamp, # with precision
        ->(_typmod) { raise '?' }, # current_role,
        ->(_typmod) { raise '?' }, # current_user,
        ->(_typmod) { raise '?' }, # session_user,
        ->(_typmod) { raise '?' }, # user,
        ->(_typmod) { raise '?' }, # current_catalog,
        ->(_typmod) { raise '?' } # current_schema
      ][op].call(typmod)
    end

    def visit_A_Indirection(**attributes)
      raise '?'
    end

    def visit_Null(**_)
      Arel.sql 'NULL'
    end

    def visit_RangeFunction(**attributes)
      raise '?'
    end

    def visit_ParamRef(number: nil)
      Arel::Nodes::BindParam.new(nil)
    end

    def visit_Float(str:)
      Arel::Nodes::SqlLiteral.new str
    end

    def visit_CoalesceExpr(args:)
      args = args.map { |arg| visit(arg) }
      ::ArelExtensions::Nodes::Coalesce.new args
    end

    def visit_TypeName(names:, typemod:)
      names = names.map do |name|
        visit(name, :operator)
      end

      catalog, type = names

      if catalog != PG_CATALOG
        raise 'do not know how to handle non pg catalog types'
      end

      case type
      when 'bool'
        BOOLEAN
      else
        raise "do not know how to handle #{type}"
      end
    end

    def visit_TypeCast(arg:, typeName:)
      arg = visit(arg)
      type_name = visit(typeName)

      case type_name
      when BOOLEAN
        # TODO: Maybe we can do this a bit better
        arg == '\'t\'' ? Arel::Nodes::True.new : Arel::Nodes::False.new
      else
        raise '?'
      end
    end

    def visit_JoinExpr(jointype:, isNatural: nil, larg:, rarg:, quals:)
      join_class = case jointype
                   when 0
                     if isNatural
                       raise 'do not know to natural join'
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

    def visit_WindowDef(partitionClause: [], orderClause: [], frameOptions:)
      Arel::Nodes::Window.new.tap do |window|
        window.orders = orderClause.map {|x| visit x }
        window.partitions = partitionClause.map {|x| visit x }
      end
    end

    def visit_FuncCall(
          args: nil,
          funcname:,
          agg_star: nil,
          agg_distinct: nil,
          over: nil
        )
      args = if args
               args.map { |arg| visit(arg) }
             elsif agg_star
               [Arel.star]
             end

      func_name = funcname[0]['String']['str']

      case func_name
      when 'sum'
        Arel::Nodes::Sum.new args

      when 'rank'
        Arel::Nodes::Over.new(
          Arel::Nodes::NamedFunction.new('RANK', args),
          visit(over)
        )

      when 'count'
        Arel::Nodes::Count.new args

      when 'generate_series'
        Arel::Nodes::NamedFunction.new('GENERATE_SERIES', args)

      else
        raise "? -> #{func_name}"
      end
    end

    def visit_SelectStmt(
          fromClause: nil,
          limitCount: nil,
          targetList:,
          sortClause: nil,
          whereClause: nil,
          limitOffset: nil,
          distinctClause: nil,
          op:
        )
      froms, join_sources = generate_sources(fromClause)
      limit = generate_limit(limitCount)
      targets = generate_targets(targetList)
      sorts = generate_sorts(sortClause)
      wheres = generate_wheres(whereClause)
      offset = generate_offset(limitOffset)

      select_core = Arel::Nodes::SelectCore.new
      select_core.projections = targets
      select_core.from = froms.first if froms
      select_core.wheres = [wheres] if wheres
      select_core.source.right = join_sources

      # TODO: We have to deal with DISTINCT ON!
      select_core.set_quantifier = Arel::Nodes::Distinct.new if distinctClause

      select_statement = Arel::Nodes::SelectStatement.new [select_core]
      select_statement.limit = limit
      select_statement.offset = offset
      select_statement.orders = sorts if sorts

      select_statement
    end

    def visit_A_Star
      Arel.star
    end

    def visit_RawStmt(stmt:)
      visit(stmt) if stmt
    end

    def visit_SortBy(node:, sortby_dir:, sortby_nulls:)
      result = visit(node)
      case sortby_dir
      when 1
        Arel::Nodes::Ascending.new(result)
      when 2
        Arel::Nodes::Descending.new(result)
      else
        result
      end
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

    def visit_BoolExpr(context = false, args:, boolop:)
      args = args.map do |arg|
        visit(arg, context || true)
      end

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

    def generate_comparison(left, right, operator)
      case operator
      when '='
        Arel::Nodes::Equality.new(left, right)
      when '<>'
        Arel::Nodes::NotEqual.new(left, right)
      when '>'
        Arel::Nodes::GreaterThan.new(left, right)
      when '>='
        Arel::Nodes::GreaterThanOrEqual.new(left, right)
      when '<'
        Arel::Nodes::LessThan.new(left, right)
      when '<='
        Arel::Nodes::LessThanOrEqual.new(left, right)
      when '*'
        Arel::Nodes::Multiplication.new(left, right)
      when '+'
        Arel::Nodes::Addition.new(left, right)
      when '-'
        Arel::Nodes::Subtraction.new(left, right)
      else
        raise "Dunno operator `#{operator}`"
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

    def generate_distinct(distinct)
      return if distinct.nil?

      ::Arel::Nodes::Offset.new visit(limit_offset)
    end

    def generate_offset(limit_offset)
      return if limit_offset.nil?

      ::Arel::Nodes::Offset.new visit(limit_offset)
    end

    def generate_wheres(where)
      return if where.nil?

      visit(where)
    end

    def generate_limit(count)
      return if count.nil?

      ::Arel::Nodes::Limit.new visit(count)
    end

    def generate_targets(list)
      return if list.nil?

      list.map { |target| visit(target) }
    end

    def generate_sorts(sorts)
      return [] if sorts.nil?

      sorts.map { |sort| visit(sort) }
    end

    def generate_sources(clause)
      froms = []
      join_sources = []

      if (from_clauses = clause)
        results =
          from_clauses.map { |from_clause| visit(from_clause) }
            .flatten

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
  end

  class Error < StandardError; end
  class MultiTableError < Error; end

  def self.parse(sql)
    tree = PgQuery.parse(sql).tree
    Visitor.new.accept(tree.first) # DUNNO Y .first
  end

  def self.manager_from_statement(statement)
    type = statement.keys.first
    ast = statement[type]

    case type
    when PgQuery::SELECT_STMT
      create_select_manager(ast)
    else
      raise "unknown statement type `#{type}`"
    end
  end

  def self.create_select_manager(ast)
    # from_clauses = ast.fetch('fromClause')
    # raise MultiTableError, 'Can not handle multiple tables' if from_clauses.length > 1
    # from_clause = from_clauses.first
    # table = RangeVar.new(**symbolize_keys(from_clause.fetch('RangeVar'))).to_arel

    # puts ast

    # target_lists = ast.fetch('targetList').map do |target_list|
    #   ResTarget.new(**symbolize_keys(target_list.fetch('ResTarget'))).to_arel
    # end

    # a = Arel::SelectManager.new table
    # b = a.project(target_lists)
    # binding.pry
  end
end
# rubocop:enable Naming/MethodName
