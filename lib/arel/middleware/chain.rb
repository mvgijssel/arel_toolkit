# typed: true
module Arel
  module Middleware
    class Chain
      sig { params(internal_middleware: T::Array[Class], internal_context: T::Hash).void }
      def initialize(internal_middleware = [], internal_context = {})
        @internal_middleware = internal_middleware
        @internal_context = internal_context
      end

      sig { params(sql: String, binds: T::Array).returns(String) }
      def execute(sql, binds = [])
        return sql if internal_middleware.length.zero?

        result = Arel.sql_to_arel(sql, binds: binds)
        updated_context = context.merge(original_sql: sql)

        internal_middleware.each do |middleware_item|
          result = result.map do |arel|
            middleware_item.call(arel, updated_context)
          end
        end

        result.to_sql
      end

      sig { returns(T::Array) }
      def current
        internal_middleware.dup
      end

      sig { params(middleware: T::Array[Class], block: Proc).returns(T.any(T::Array[Class], ActiveRecord::Relation, T::Boolean, Post, String, Arel::Middleware::Chain)) }
      def apply(middleware, &block)
        continue_chain(middleware, internal_context, &block)
      end

      sig { params(middleware: T::Array[Class], block: Proc).returns(T::Array[Class]) }
      def only(middleware, &block)
        continue_chain(middleware, internal_context, &block)
      end

      sig { params(block: Proc).returns(T.any(T::Array, T::Boolean, ActiveRecord::Relation)) }
      def none(&block)
        continue_chain([], internal_context, &block)
      end

      sig { params(without_middleware: Class, block: Proc).returns(ActiveRecord::Relation) }
      def except(without_middleware, &block)
        new_middleware = internal_middleware.reject do |middleware|
          middleware == without_middleware
        end

        continue_chain(new_middleware, internal_context, &block)
      end

      sig { params(new_middleware: Class, existing_middleware: Class, block: Proc).returns(T::Array[Class]) }
      def insert_before(new_middleware, existing_middleware, &block)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index, new_middleware)
        continue_chain(updated_middleware, internal_context, &block)
      end

      sig { params(new_middleware: Class, existing_middleware: Class, block: Proc).returns(T::Array[Class]) }
      def insert_after(new_middleware, existing_middleware, &block)
        index = internal_middleware.index(existing_middleware)
        updated_middleware = internal_middleware.insert(index + 1, new_middleware)
        continue_chain(updated_middleware, internal_context, &block)
      end

      sig { params(new_context: T::Hash[Symbol, Symbol], block: Proc).returns(T.any(T::Boolean, ActiveRecord::Relation)) }
      def context(new_context = nil, &block)
        if new_context.nil? && !block.nil?
          raise 'You cannot do a block statement while calling context without arguments'
        end

        return internal_context if new_context.nil?

        continue_chain(internal_middleware, new_context, &block)
      end

      protected

      attr_reader :internal_middleware
      attr_reader :internal_context

      private

      sig { params(middleware: T::Array[Class], context: T::Hash, block: Proc).returns(T.any(T::Array[Class], ActiveRecord::Relation, T::Boolean, Post, String, Arel::Middleware::Chain)) }
      def continue_chain(middleware, context, &block)
        new_chain = Arel::Middleware::Chain.new(middleware, context)
        maybe_execute_block(new_chain, &block)
      end

      sig { params(new_chain: Arel::Middleware::Chain, block: Proc).returns(T.any(T::Array[Class], ActiveRecord::Relation, T::Boolean, Post, String)) }
      def maybe_execute_block(new_chain, &block)
        return new_chain if block.nil?

        previous_chain = Middleware.current_chain
        Arel::Middleware.current_chain = new_chain
        yield block
      ensure
        Arel::Middleware.current_chain = T.must(previous_chain)
      end

      sig { returns(T.untyped) }
      def current_chain
        Arel::Middleware.current_chain
      end
    end
  end
end