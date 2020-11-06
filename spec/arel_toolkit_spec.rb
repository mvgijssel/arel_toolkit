describe ArelToolkit do
  it 'has a version number' do
    expect(ArelToolkit::VERSION).not_to be nil
  end

  it 'has version of Arel corresponding to ActiveRecord' do
    arel_version = ActiveRecord.version.version.to_i == 6 ? 10 : 9
    expect(Arel::VERSION.to_i).to be arel_version
  end
end
