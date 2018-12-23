require 'to_arel/version'
require 'arel'
require 'pg_query'

def symbolize_keys(hash)
  Hash[hash.map { |k, v| [k.to_sym, v] }]
end

# rubocop:disable Naming/MethodName
module ToArel
  class UnboundColumnReference < ::Arel::Nodes::SqlLiteral; end

  class Visitor
    attr_reader :object

    def accept(object)
      @object = object
      pp object
      visit(*klass_and_attributes(object))
    end

    private

    def visit(klass, attributes, context = nil)
      dispatch_method = "visit_#{klass}"
      args = [klass, attributes]
      method = method(dispatch_method)

      args = case method.arity
             when 2
               args
             when -3
               if context.nil?
                 args
               else
                 args.concat([context])
               end
             else
               raise 'unknown arity'
             end

      send dispatch_method, *args
    end

    def klass_and_attributes(object)
      [object.keys.first, object.values.first]
    end

    def visit_String(_klass, attributes, context = nil)
      case context
      when :operator
        attributes['str']
      else
        "\"#{attributes['str']}\""
      end
    end

    def visit_Integer(_klass, attributes)
      attributes['ival']
    end

    def visit_ColumnRef(_klass, attributes)
      UnboundColumnReference.new(
        attributes['fields'].map do |field|
          visit(*klass_and_attributes(field))
        end.join('.') # TODO: Join . might be a poor assumption
      )
    end

    def visit_ResTarget(_klass, attributes)
      visit(*klass_and_attributes(attributes['val']))
    end

    def visit_SubLink(_klass, attributes)
      type = attributes['subLinkType']
      case type
      when 4
        visit(*klass_and_attributes(attributes['subselect']))
      else
        raise "Unknown sublinktype: #{type}"
      end
    end

    def visit_Alias(_klass, attributes)
      attributes['aliasname']
    end

    def visit_RangeVar(_klass, attributes)
      table_alias = (visit(*klass_and_attributes(attributes['alias'])) if attributes['alias'])

      Arel::Table.new attributes['relname'], as: table_alias
    end

    def visit_A_Expr(_klass, attributes, context = false)
      # case node['kind']
      # when AEXPR_OP
      #   output = []
      #   output << deparse_item(node['lexpr'], context || true)
      #   output << deparse_item(node['rexpr'], context || true)
      #   output = output.join(' ' + deparse_item(node['name'][0], :operator) + ' ')
      #   if context
      #     # This is a nested expression, add parentheses.
      #     output = '(' + output + ')'
      #   end
      #   output
      # when AEXPR_OP_ANY
      #   deparse_aexpr_any(node)
      # when AEXPR_IN
      #   deparse_aexpr_in(node)
      # when CONSTR_TYPE_FOREIGN
      #   deparse_aexpr_like(node)
      # when AEXPR_BETWEEN, AEXPR_NOT_BETWEEN, AEXPR_BETWEEN_SYM, AEXPR_NOT_BETWEEN_SYM
      #   deparse_aexpr_between(node)
      # when AEXPR_NULLIF
      #   deparse_aexpr_nullif(node)
      # else
      #   raise format("Can't deparse: %s: %s", type, node.inspect)
      # end

      case attributes['kind']
      when 0
        left = visit(*klass_and_attributes(attributes['lexpr']), context || true)
        right = visit(*klass_and_attributes(attributes['rexpr']), context || true)
        operator = visit(*klass_and_attributes(attributes['name'][0]), :operator)

        case operator
        when '='
          left.eq(right)
        else
          raise 'dunno operator'
        end
      else
        raise 'dunno kind'
      end
    end

    def visit_A_Const(_klass, attributes)
      visit(*klass_and_attributes(attributes['val']))
    end

    def visit_JoinExpr(_klass, attributes)
      # case node['jointype']
      # when 0
      #   if node['isNatural']
      #     output << 'NATURAL'
      #   elsif node['quals'].nil? && node['usingClause'].nil?
      #     output << 'CROSS'
      #   end
      # when 1
      #   output << 'LEFT'
      # when 2
      #   output << 'FULL'
      # when 3
      #   output << 'RIGHT'
      # end
      join_class = case attributes['jointype']
                   when 0
                     Arel::Nodes::InnerJoin
                   when 1
                     Arel::Nodes::OuterJoin
                   when 2
                     Arel::Nodes::FullOuterJoin
                   when 3
                     Arel::Nodes::RightOuterJoin
                   end

      larg = visit(*klass_and_attributes(attributes['larg']))
      rarg = visit(*klass_and_attributes(attributes['rarg']))
      quals = visit(*klass_and_attributes(attributes['quals']))

      join = join_class.new(rarg, quals)

      if larg.is_a?(Array)
        larg.concat([join])
      else
        [larg, join]
      end
    end

    def visit_FuncCall(_klass, attributes)
      args = attributes['args'].map { |arg| visit(*klass_and_attributes(arg)) }

      # TODO: Everything is a count :)
      Arel::Nodes::Count.new args
    end

    def visit_SelectStmt(_klass, attributes)
      froms, join_sources = generate_sources(attributes['fromClause'])
      limit = generate_limit(attributes['limitCount'])
      targets = generate_targets(attributes['targetList'])
      sorts = generate_sorts(attributes['sortClause'])

      select_manager = Arel::SelectManager.new(froms)
      select_manager.projections = targets
      select_manager.limit = limit

      sorts.each do |sort|
        select_manager.order(sort)
      end

      join_sources.each do |join_source|
        select_manager.join(join_source.left, join_source.class).on(join_source.right)
      end

      select_manager
    end

    def visit_A_Star(_klass, _attributes)
      Arel.star
    end

    def visit_RawStmt(_klass, attributes)
      return unless (stmt = attributes['stmt'])

      visit(*klass_and_attributes(stmt))
    end

    def visit_SortBy(_klass, attributes)
      result = visit(*klass_and_attributes(attributes['node']))
      case attributes['sortby_dir']
      when 1
        Arel::Nodes::Ascending.new(result)
      when 2
        Arel::Nodes::Descending.new(result)
      else
        raise 'unknown sort direction'
      end
    end

    def generate_limit(count)
      return if count.nil?

      visit(*klass_and_attributes(count))
    end

    def generate_targets(list)
      return if list.nil?

      list.map { |target| visit(*klass_and_attributes(target)) }
    end

    def generate_sorts(sorts)
      return [] if sorts.nil?

      sorts.map { |sort| visit(*klass_and_attributes(sort)) }
    end

    def generate_sources(clause)
      froms = []
      join_sources = []

      if (from_clauses = clause)
        results = from_clauses.map { |from_clause| visit(*klass_and_attributes(from_clause)) }
          .flatten

        results.each do |result|
          if result.is_a?(Arel::Table)
            froms << result
          else
            join_sources << result
          end
        end
      end

      [froms, join_sources]
    end
  end

  class Error < StandardError; end
  class MultiTableError < Error; end

  def self.parse(sql)
    tree = PgQuery.parse(sql).tree
    puts tree

    Visitor.new.accept(tree.first) # DUNNO Y .first
  end

  def self.manager_from_statement(statement)
    type = statement.keys.first
    ast = statement[type]

    case type
    when 'SelectStmt'
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
