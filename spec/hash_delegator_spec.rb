RSpec.describe HashDelegator do
  it "has a version number" do
    expect(HashDelegator::VERSION).not_to be nil
  end

  class Person < HashDelegator
    require :name, :age
  end

  it "should raise an exception if " do
    expect(false).to eq(true)
  end
end
