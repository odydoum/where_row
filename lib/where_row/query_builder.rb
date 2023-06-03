module WhereRow
  class QueryBuilder
    def initialize(relation, keys, operator, values)
      @relation = relation
      @keys = keys.map(&:to_s)
      @operator = operator
      @values = values
    end

    REVERSE_OP_MAP = {
      lt: :gteq,
      gt: :lteq,
      lteq: :gt,
      gteq: :lt
    }.freeze
    private_constant :REVERSE_OP_MAP

    COMPARISON_OPERATORS = REVERSE_OP_MAP.keys
    private_constant :COMPARISON_OPERATORS

    def build
      return relation if keys.blank?

      case operator
      when :eq
        validate_single(values)
        relation.where(keys.zip(values).to_h)
      when :not_eq
        validate_single(values)
        build_not_eq_clause(relation, keys.zip(values))
      when :in
        validate_multiple(values)
        build_in_clause
      when :not_in
        validate_multiple(values)
        build_not_in_clause
      when *COMPARISON_OPERATORS
        validate_single(values)
        build_comparison_clause
      else
        raise ArgumentError, 'Invalid operator'
      end
    end

    private

    attr_reader :relation, :keys, :operator, :values

    def build_not_eq_clause(rel, key_value_pairs)
      key, value = key_value_pairs.first

      base_relation = rel.where.not(key => value)

      return base_relation if key_value_pairs.length == 1

      key_value_pairs[1..-1].reduce(base_relation) do |r, (k, v)|
        r.or!(rel.where.not(k => v))
      end
    end

    def build_in_clause
      in_relation = relation.unscoped.where!(keys.zip(values.first).to_h)

      values[1..-1].each do |v|
        in_relation.or!(relation.unscoped.where!(keys.zip(v).to_h))
      end

      relation.merge(in_relation)
    end

    def build_not_in_clause
      base_relation = build_not_eq_clause(relation, keys.zip(values.first))

      return base_relation if values.length == 1

      values[1..-1].reduce(base_relation) do |r, v|
        base_relation.merge!(build_not_eq_clause(relation, keys.zip(v)))
      end
    end

    def build_comparison_clause
      relation.where(build_comparison_predicate)
    end

    def build_comparison_predicate
      last_idx = keys.size - 1
      reversed_op = REVERSE_OP_MAP[operator]
      last_pred = build_predicate_for_key(relation, last_idx, reversed_op)

      return last_pred if last_idx.zero?

      first_keys_op = :lt if reversed_op == :lteq
      first_keys_op = :gt if reversed_op == :gteq
      first_keys_op ||= reversed_op

      (0...last_idx).
        map { |i| build_predicate_for_key(relation, i, first_keys_op) }.
        reduce(:and).
        and(last_pred)
    end

    def build_predicate_for_key(relation, idx, op)
      last_pred = build_predicate(relation, keys[idx], values[idx], op)

      return last_pred.not if idx == 0

      (0...idx).
        map { |j| build_predicate(relation, keys[j], values[j], :eq) }.
        reduce(:and).
        and(last_pred).
        not
    end

    def build_predicate(relation, attr_name, value, operator)
      relation.arel_table[attr_name].public_send(operator, value)
    end

    def validate_single(values)
      if keys.length != values.length
        raise ArgumentError, 'Argument lengths do not match'
      end
    end

    def validate_multiple(values)
      values.each { |v| validate_single(v) }
    end
  end
end
