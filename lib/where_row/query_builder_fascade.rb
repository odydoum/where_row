require 'where_row/query_builder'

module WhereRow
  class QueryBuilderFascade
    def initialize(relation, keys, negated = false)
      @relation = relation
      @keys = keys
      @negated = negated
    end

    #
    # Negate the where_row condition that follows
    #
    # @example
    #   Rel.where_row(:c1, c2).eq(v1, v2) # Generates the equivalent of (c1, c2) = (v1, v2)
    #   Rel.where_row(:c1, c2).not.eq(v1, v2) # Generates the equivalent of (c1, c2) != (v1, v2)
    #
    # @return [WhereRow::QueryBuilderFascade]
    #
    def not
      self.class.new(@relation, @keys, true)
    end

    #
    # Generates the equivalent clause of (c1, c2, c3, ...) = (v1, v2, v3, ...)
    #
    # @param [Array<Object>] values The values to compare against
    #
    # @return [ActiveRecord::Relation] The resulting relation
    #
    def eq(*values)
      op = @negated ? :not_eq : :eq

      QueryBuilder.new(@relation, @keys, op, values).build
    end

    #
    # Generates the equivalent clause of (c1, c2, c3, ...) IN ((a1, a2, a3, ...), (b1, b2, b3, ...))
    #
    # @param [Array<Array<Object>>] values The values to compare against. Each element is itself an array of values.
    #
    # @return [ActiveRecord::Relation] The resulting relation
    #
    def in(*values)
      op = @negated ? :not_in : :in

      QueryBuilder.new(@relation, @keys, op, values).build
    end

    def in_range(range)
      if @negated
        result = @relation.where_row(@keys).lt(range.begin)

        if range.exclude_end?
          result.or(@relation.where_row(@keys).gte(range.end))
        else
          result.or(@relation.where_row(@keys).gt(range.end))
        end
      else
        result = @relation.where_row(@keys).gte(range.begin)

        if range.exclude_end?
          result.where_row(@keys).lt(range.end)
        else
          result.where_row(@keys).lte(range.end)
        end
      end
    end

    #
    # Generates the equivalent clause of (c1, c2, c3, ...) > (v1, v2, v3, ...)
    #
    # @param [Array<Object>] values The values to compare against
    #
    # @return [ActiveRecord::Relation] The resulting relation
    #
    def gt(*values)
      op = @negated ? :lteq : :gt

      QueryBuilder.new(@relation, @keys, op, values).build
    end

    #
    # Generates the equivalent clause of (c1, c2, c3, ...) >= (v1, v2, v3, ...)
    #
    # @param [Array<Object>] values The values to compare against
    #
    # @return [ActiveRecord::Relation] The resulting relation
    #
    def gte(*values)
      op = @negated ? :lt : :gteq

      QueryBuilder.new(@relation, @keys, op, values).build
    end

    #
    # Generates the equivalent clause of (c1, c2, c3, ...) < (v1, v2, v3, ...)
    #
    # @param [Array<Object>] values The values to compare against
    #
    # @return [ActiveRecord::Relation] The resulting relation
    #
    def lt(*values)
      op = @negated ? :gteq : :lt

      QueryBuilder.new(@relation, @keys, op, values).build
    end

    #
    # Generates the equivalent clause of (c1, c2, c3, ...) <= (v1, v2, v3, ...)
    #
    # @param [Array<Object>] values The values to compare against
    #
    # @return [ActiveRecord::Relation] The resulting relation
    #
    def lte(*values)
      op = @negated ? :gt : :lteq

      QueryBuilder.new(@relation, @keys, op, values).build
    end
  end
end
