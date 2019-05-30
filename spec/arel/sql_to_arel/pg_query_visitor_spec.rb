describe Arel::SqlToArel::PgQueryVisitor do
  describe 'accept' do
    it 'raises an exception with more than 1 SQL statement' do
      sql = <<~SQL
        SELECT 1; -- statement 1
        SELECT 2; -- statement 2
      SQL

      expect { described_class.new.accept(sql) }
        .to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/33')
    end
  end

  describe 'visit_A_Expr' do
    it 'raises an exception with a PgQuery::AEXPR_OF statement' do
      expect do
        described_class.new.send(:visit_A_Expr, kind: PgQuery::AEXPR_OF, name: 'name')
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/34')
    end

    it 'raises an exception with a PgQuery::AEXPR_PAREN statement' do
      expect do
        described_class.new.send(:visit_A_Expr, kind: PgQuery::AEXPR_PAREN, name: 'name')
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/35')
    end
  end

  describe 'visit_RangeFunction' do
    it 'raises an exception when is_rowsfrom is not true' do
      expect do
        described_class.new.send(:visit_RangeFunction, is_rowsfrom: false, functions: [])
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/36')
    end

    it 'raises an exception when functions does not contain nil' do
      functions = [%w[some_function something_else]]
      expect do
        described_class.new.send(:visit_RangeFunction, is_rowsfrom: true, functions: functions)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/37')
    end
  end

  describe 'visit_SelectStmt' do
    it 'raises an exception if op is not zero' do
      expect do
        described_class.new.send(:visit_SelectStmt, op: 1)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/38')
    end
  end

  describe 'visit_SubLink' do
    it 'raises an exception when typemod is not -1' do
      oper_name = [
        { 'String' => { 'str' => '=' } },
        { 'String' => { 'str' => '>' } },
      ]
      expect do
        described_class.new.send(
          :visit_SubLink,
          subselect: [],
          sub_link_type: 1,
          oper_name: oper_name,
        )
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/39')
    end
  end

  describe 'visit_TypeName' do
    it 'raises an exception when typemod is not -1' do
      expect do
        described_class.new.send(:visit_TypeName, names: [], typemod: 1)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/40')
    end

    it 'raises an exception when names contains more than 2 items' do
      names = [
        { 'String' => { 'str' => Arel::SqlToArel::PgQueryVisitor::PG_CATALOG } },
        { 'String' => { 'str' => 'bool' } },
        { 'String' => { 'str' => 'bpchar' } },
      ]

      expect do
        described_class.new.send(:visit_TypeName, names: names, typemod: -1)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/41')
    end
  end

  describe 'generate_sublink' do
    it 'raises an exception when sub_link_type is PgQuery::SUBLINK_TYPE_ROWCOMPARE' do
      expect do
        described_class.new.send(:generate_sublink, PgQuery::SUBLINK_TYPE_ROWCOMPARE, nil, nil, nil)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/42')
    end

    it 'raises an exception when sub_link_type is PgQuery::SUBLINK_TYPE_MULTIEXPR' do
      expect do
        described_class.new.send(:generate_sublink, PgQuery::SUBLINK_TYPE_MULTIEXPR, nil, nil, nil)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/43')
    end

    it 'raises an exception when sub_link_type is PgQuery::SUBLINK_TYPE_ROWCOMPARE' do
      expect do
        described_class.new.send(:generate_sublink, PgQuery::SUBLINK_TYPE_CTE, nil, nil, nil)
      end.to raise_error('https://github.com/mvgijssel/arel_toolkit/issues/44')
    end
  end
end
