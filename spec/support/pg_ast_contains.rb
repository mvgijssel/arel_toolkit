RSpec::Matchers.define :pg_ast_contains do |expected|
  def ast_contains_constant(
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize
    tree, constant
  )
    case tree
    when Array
      tree.any? { |child| ast_contains_constant(child, constant) }
    when Hash
      tree.any? do |key, value|
        next true if key.to_s == constant.to_s

        ast_contains_constant(value, constant)
      end
    when String
      tree.to_s == constant.to_s
    when Integer
      tree.to_s == constant.to_s
    when TrueClass
      tree.to_s == constant.to_s
    when FalseClass
      tree.to_s == constant.to_s
    when NilClass
      tree.to_s == constant.to_s
    else
      raise '?'
    end
  end

  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/AbcSize
  match { |pg_query_tree| ast_contains_constant(pg_query_tree, expected) }

  failure_message { |pg_query_tree| "expected that #{pg_query_tree} would contain `#{expected}`" }
end
