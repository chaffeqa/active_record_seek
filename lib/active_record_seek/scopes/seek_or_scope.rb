=begin
Student.seek_or(self) do |this|
  add_scope { where(...) }
  add_scope { where(...).where(...) }
end
=end
module ActiveRecordSeek
  module Scopes
    class SeekOrScope < BaseScope

      attr_accessor(*%w[ context_block ])

      def apply(query, *context_arguments, &context_block)
        context = Context.new(query.klass)
        context.instance_exec(*context_arguments, &context_block)
        # combine queries into single OR clause
        query.where(context.to_where_sql)
      end

      class Context
        attr_accessor(*%w[ klass queries enclose_with_parentheses ])

        def initialize(klass)
          self.klass   = klass
          self.queries = []
          self.enclose_with_parentheses = false
        end

        def add_query(&block)
          unscoped_query = klass.unscoped
          query = unscoped_query.instance_exec(unscoped_query, &block).to_seek_query
          queries.push(query) if query.has_where_sql?
          self
        end

        def to_where_sql
          queries.map do |query|
            query.to_where_sql(enclose_with_parentheses: enclose_with_parentheses)
          end.join(" OR ")
        end
      end

      module ActiveRecordScopeConcern

        extend ActiveSupport::Concern

        class_methods do
          def seek_or(*params, &block)
            SeekOrScope.new.apply(all, *params, &block)
          end
        end

      end


    end
  end
end
