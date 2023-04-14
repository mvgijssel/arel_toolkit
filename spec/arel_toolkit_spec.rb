describe ArelToolkit do
  it 'has a version number' do
    expect(ArelToolkit::VERSION).not_to be nil
  end

  it 'has version of Arel corresponding to ActiveRecord' do
    expect(Arel::VERSION.to_i).to be 10
  end
end
