RSpec.describe WhereRow do
  before do
    class TestRecord < ActiveRecord::Base
    end

    ActiveRecord::Schema.verbose = false
    ActiveRecord::Schema.define(version: 1) do
      create_table :test_records do |t|
        t.integer :col1
        t.integer :col2
        t.integer :col3
        t.integer :filter_col

        t.timestamps
      end
    end
  end

  it "has a version number" do
    expect(WhereRow::VERSION).not_to be nil
  end

  describe '#where_row' do
    let(:base_relation) { TestRecord }
    let(:relation) { base_relation }

    context 'when no arguments are provided' do
      subject { relation.where_row }

      it { expect { subject }.to raise_error ArgumentError }
    end

    describe '#eq' do
      subject { relation.where_row(:col1, :col2, :col3).eq(1, 2, 3) }

      let!(:r1) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }
      let!(:r2) { TestRecord.create!(col1: 4, col2: 5, col3: 6) }
      let!(:r4) { TestRecord.create!(col1: 1, col2: 2, col3: 3, filter_col: 5) }

      context 'when the relation is unscoped' do
        let(:relation) { base_relation.unscoped }

        it 'returns the correct records' do
          is_expected.to contain_exactly(r1, r4)
        end
      end

      context 'when the relation has a filter' do
        let(:relation) { base_relation.where(filter_col: 5) }

        it 'returns the correct records' do
          is_expected.to contain_exactly(r4)
        end
      end

      context 'when compared against NULL' do
        let!(:r1) { TestRecord.create!(col1: 1, col2: nil, col3: 3) }

        it 'returns the correct records' do
          is_expected.to contain_exactly(r4)
        end

        context 'and testing explicitely for NULL on a collumn' do
          subject { relation.where_row(:col1, :col2, :col3).eq(1, nil, 3) }

          it 'returns the correct records' do
            is_expected.to contain_exactly(r1)
          end
        end
      end

      context 'when one argument is provided' do
        subject { relation.where_row(:col1).eq(2) }

        it 'generates the correct relation' do
          is_expected.to eq(relation.where(col1: 2))
        end
      end

      context 'when the number of arguments do not match' do
        subject { relation.where_row(:col1, :col2, :col3).eq(1, 2) }

        it { expect { subject }.to raise_error ArgumentError, 'Argument lengths do not match' }
      end

      context 'when no arguments are provided' do
        subject { relation.where_row(:col1, :col2, :col3).eq }

        it { expect { subject }.to raise_error ArgumentError, 'Argument lengths do not match' }
      end
    end

    describe '#in' do
      subject do
        relation.where_row(:col1, :col2, :col3).in([1, 2, 3], [4, 5, 6])
      end

      let!(:r1) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }
      let!(:r2) { TestRecord.create!(col1: 4, col2: 5, col3: 6, filter_col: 4) }
      let!(:r3) { TestRecord.create!(col1: 1, col2: 2, col3: nil) }
      let!(:r4) { TestRecord.create!(col1: 1, col2: 2, col3: 3, filter_col: 5) }

      context 'when the relation is unscoped' do
        let(:relation) { base_relation.unscoped }

        it 'returns the correct records' do
          is_expected.to contain_exactly(r1, r2, r4)
        end
      end

      context 'when the relation is ordered' do
        let(:relation) { base_relation.order(filter_col: :desc) }

        it 'returns the correct records' do
          is_expected.to eq([r4, r2, r1])
        end
      end

      context 'when the relation has a filter' do
        let(:relation) { base_relation.where(filter_col: 5) }

        it 'returns the correct records' do
          is_expected.to contain_exactly(r4)
        end
      end

      context 'when the relation has select clause and a filter' do
        let(:relation) { base_relation.where(created_at: DateTime.new(2021, 5, 8, 15)).select(:id) }

        it 'generates the correct relation' do
          is_expected.to eq(
            relation.where(col1: 1, col2: 2, col3: 3).or(
              relation.where(col1: 4, col2: 5, col3: 6))
          )
        end
      end

      context 'when the number of arguments do not match' do
        subject do
          relation.where_row(:col1, :col2, :col3).in([1, 2, 3], [6])
        end

        it { expect { subject }.to raise_error ArgumentError, 'Argument lengths do not match' }
      end
    end

    describe '#lt' do
      subject { relation.where_row(:col1, :col2, :col3).lt(*test_values) }

      let(:test_values) { [1, 2, 3] }
      let!(:record) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }

      context 'when the record values are eq to the test values' do
        it { is_expected.to be_empty }
      end

      # (1,2,3) < (2,3,4)
      context 'when all values are less than the test values' do
        let(:test_values) { [2, 3, 4] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) < (1,2,4)
      context 'when the first two values are equal and the third less' do
        let(:test_values) { [1, 2, 4] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) < (1,3,nil)
      context 'when the last test value is nil, but the condition holds for the previous' do
        let(:test_values) { [1, 3, nil] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) < (1,2,nil)
      context 'when the last test value is nil, and the rest are equal' do
        let(:test_values) { [1, 2, nil] }

        it { is_expected.to be_empty }
      end

      # (1,2,3) < (1,1,nil)
      context 'when the last test value is nil, but the condition does not hold for the previous' do
        let(:test_values) { [1, 1, nil] }

        it { is_expected.to be_empty }
      end
    end

    describe '#lte' do
      subject { relation.where_row(:col1, :col2, :col3).lte(*test_values) }

      let(:test_values) { [1, 2, 3] }
      let!(:record) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }

      context 'when the record values are eq to the test values' do
        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) <= (2,3,4)
      context 'when all values are less than the test values' do
        let(:test_values) { [2, 3, 4] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) <= (1,2,4)
      context 'when the first two values are equal and the third less' do
        let(:test_values) { [1, 2, 4] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) <= (1,3,nil)
      context 'when the last test value is nil, but the condition holds for the previous' do
        let(:test_values) { [1, 3, nil] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) < (1,2,nil)
      context 'when the last test value is nil, and the rest are equal' do
        let(:test_values) { [1, 2, nil] }

        it { is_expected.to be_empty }
      end

      # (1,2,3) <= (1,1,nil)
      context 'when the last test value is nil, but the condition does not hold for the previous' do
        let(:test_values) { [1, 1, nil] }

        it { is_expected.to be_empty }
      end
    end

    describe '#gt' do
      subject { relation.where_row(:col1, :col2, :col3).gt(*test_values) }

      let(:test_values) { [1, 2, 3] }
      let!(:record) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }

      context 'when the record values are eq to the test values' do
        it { is_expected.to be_empty }
      end

      # (1,2,3) > (0,1,2)
      context 'when all values are greater than the test values' do
        let(:test_values) { [0, 1, 2] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (1,2,1)
      context 'when the first two values are equal and the third greater' do
        let(:test_values) { [1, 2, 1] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (1,1,nil)
      context 'when the last test value is nil, but the condition holds for the previous' do
        let(:test_values) { [1, 1, nil] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (1,2,nil)
      context 'when the last test value is nil, and the rest are equal' do
        let(:test_values) { [1, 2, nil] }

        it { is_expected.to be_empty }
      end

      # (1,2,3) > (1,3,nil)
      context 'when the last test value is nil, but the condition does not hold for the previous' do
        let(:test_values) { [1, 3, nil] }

        it { is_expected.to be_empty }
      end
    end

    describe '#gte' do
      subject { relation.where_row(:col1, :col2, :col3).gte(*test_values) }

      let(:test_values) { [1, 2, 3] }
      let!(:record) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }

      context 'when the record values are eq to the test values' do
        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (0,1,2)
      context 'when all values are greater than the test values' do
        let(:test_values) { [0, 1, 2] }

        it { 
              p subject.to_sql

          is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (1,2,1)
      context 'when the first two values are equal and the third greater' do
        let(:test_values) { [1, 2, 1] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (1,1,nil)
      context 'when the last test value is nil, but the condition holds for the previous' do
        let(:test_values) { [1, 1, nil] }

        it { is_expected.to contain_exactly(record) }
      end

      # (1,2,3) > (1,2,nil)
      context 'when the last test value is nil, and the rest are equal' do
        let(:test_values) { [1, 2, nil] }

        it { is_expected.to be_empty }
      end

      # (1,2,3) > (1,3,nil)
      context 'when the last test value is nil, but the condition does not hold for the previous' do
        let(:test_values) { [1, 3, nil] }

        it { is_expected.to be_empty }
      end
    end

    describe '#not' do
      describe '#eq' do
        subject { relation.where_row(:col1, :col2, :col3).not.eq(1, 2, 3) }

        let!(:r1) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }
        let!(:r2) { TestRecord.create!(col1: 4, col2: 5, col3: 6, filter_col: 5) }
        let!(:r4) { TestRecord.create!(col1: 1, col2: 2, col3: 3, filter_col: 5) }

        context 'when the relation is unscoped' do
          let(:relation) { base_relation.unscoped }

          it 'returns the correct records' do
            is_expected.to contain_exactly(r2)
          end
        end

        context 'when the relation has a filter' do
          let(:relation) { base_relation.where(filter_col: 5) }

          it 'returns the correct records' do
            is_expected.to contain_exactly(r2)
          end
        end

        context 'when compared against NULL' do
          let!(:r1) { TestRecord.create!(col1: 1, col2: nil, col3: 3) }
          let!(:r3) { TestRecord.create!(col1: 1, col2: nil, col3: 4) }

          it 'returns the correct records' do
            is_expected.to contain_exactly(r2, r3)
          end

          context 'and testing explicitely for NULL on a collumn' do
            subject { relation.where_row(:col1, :col2, :col3).eq(1, nil, 3) }

            it 'returns the correct records' do
              is_expected.to contain_exactly(r1)
            end
          end
        end

        context 'when one argument is provided' do
          subject { relation.where_row(:col1).eq(2) }

          it 'generates the correct relation' do
            is_expected.to eq(relation.where(col1: 2))
          end
        end

        context 'when the number of arguments do not match' do
          subject { relation.where_row(:col1, :col2, :col3).eq(1, 2) }

          it { expect { subject }.to raise_error ArgumentError, 'Argument lengths do not match' }
        end

        context 'when no arguments are provided' do
          subject { relation.where_row(:col1, :col2, :col3).eq }

          it { expect { subject }.to raise_error ArgumentError, 'Argument lengths do not match' }
        end
      end

      describe '#in' do
        subject do
          relation.where_row(:col1, :col2, :col3).not.in([1, 2, 3], [4, 5, 6])
        end

        let!(:r1) { TestRecord.create!(col1: 1, col2: 2, col3: 3) }
        let!(:r2) { TestRecord.create!(col1: 4, col2: 5, col3: 6, filter_col: 4) }
        let!(:r3) { TestRecord.create!(col1: 1, col2: 2, col3: nil) }
        let!(:r4) { TestRecord.create!(col1: 1, col2: 2, col3: 3, filter_col: 5) }
        let!(:r5) { TestRecord.create!(col1: 1, col2: 3, col3: nil) }
        let!(:r6) { TestRecord.create!(col1: 6, col2: 7, col3: 8, filter_col: 5) }

        context 'when the relation is unscoped' do
          let(:relation) { base_relation.unscoped }

          it 'returns the correct records' do
            # Notice that r3 is not returned, because (1,2,nil) = (1,2,3) results in NULL
            # And NOT NULL is still NULL
            is_expected.to contain_exactly(r5, r6)
          end
        end

        context 'when the relation has a filter' do
          let(:relation) { base_relation.where(filter_col: 5) }

          it 'returns the correct records' do
            is_expected.to contain_exactly(r6)
          end
        end

        context 'when the number of arguments do not match' do
          subject do
            relation.where_row(:col1, :col2, :col3).in([1, 2, 3], [6])
          end

          it { expect { subject }.to raise_error ArgumentError, 'Argument lengths do not match' }
        end
      end
    end
  end
end
