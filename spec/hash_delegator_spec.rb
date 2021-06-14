require 'date'

class Person < HashDelegator
  required :name, :age
  transform_keys(&:to_sym)
end

class Employee < Person
  required :employee_id
  default :sorry
end

class Manager < Employee
  transform_keys(&:to_s)
end

class Contractor < Employee
  default do
    Time.now
  end
end

class Friend < Person
  default ->{ DateTime.now }
end

RSpec.describe HashDelegator do
  it 'has a version number' do
    expect(HashDelegator::VERSION).not_to be nil
  end

  it 'should raise an exception if a required attribute is missing' do
    expect { Person.new(name: 'Tester') }.to raise_error(/age/)
    expect { Person.new(age: 12) }.to raise_error(/name/)
  end

  it "should respond to all the hash's keys as methods" do
    attributes = { name: 'Tester', age: 12, favorite_comic: 'Spiderman' }
    person     = Person.new(attributes)

    attributes.each do |key, value|
      expect(person.public_send(key)).to eq value
    end
  end

  it 'should transform key using the specified transformation' do
    attributes = { 'name' => 'Tester', 'age' => 12, :favorite_comic => 'Spiderman' }
    person     = Person.new(attributes)

    attributes.each do |key, value|
      expect(person[key]).to eq value
      expect(person[key.to_s]).to eq value
      expect(person[key.to_sym]).to eq value
    end
  end

  it "should inherit it's key transformer from it's superclass if it's superclass hash specified on and it has not" do
    attributes = { 'name' => 'Testy Tester', 'age' => 24, :employee_id => 1234, :department => 'IT' }
    person     = Employee.new(attributes)

    attributes.each do |key, value|
      expect(person[key]).to eq value
      expect(person[key.to_s]).to eq value
      expect(person[key.to_sym]).to eq value
    end
  end

  it "should override it's superclass' key transformer if it has one specified" do
    attributes = { 'name' => 'Testy Tester Testing', 'age' => 54, :employee_id => 12_345, :department => 'IT', 1 => 2 }
    person     = Manager.new(attributes)

    attributes.each do |key, value|
      expect(person[key]).to eq value
      expect(person[key.to_s]).to eq value
    end
  end

  it "should inherit required attributes from it's super class" do
    expect(Manager.required_attributes).to include(*Employee.required_attributes)
    expect(Employee.required_attributes).to include(*Person.required_attributes)

    expect { Manager.new(name: 'testing', age: 41) }.to raise_error(/employee_id/)
  end

  it 'should not respond to any mutable methods' do
    expect { Person.new(name: 'Peter', age: 32).merge!(employee_id: 345) }.to raise_error(NoMethodError)

    described_class::MUTATING_METHODS.each do |method|
      expect { Person.new(name: 'Janice', age: 21).public_send(method) }.to raise_error(NoMethodError)
    end
  end

  it 'should respond to any non-mutating hash methods' do
    person = Person.new(name: 'Peter', age: 32).merge(employee_id: 345)

    expect(person).to be_an_instance_of Person
    expect(person[:employee_id]).to be 345

    Hash.instance_methods.each do |method|
      next if described_class::MUTATING_METHODS.include?(method)

      expect(person.respond_to?(method)).to be true
    end
  end

  it 'should accept a default value' do
    emp = Employee.new(name: 'Testy Tester', age: 24, employee_id: 1234, department: 'IT')

    expect(emp[:test]).to be :sorry
  end

  it "should inherit it's default value from it's superclass" do
    emp = Manager.new(name: 'Testy Tester', age: 24, employee_id: 1234, department: 'IT')

    expect(emp[:test]).to be :sorry
  end

  it 'should accept a block for a default value' do
    emp = Contractor.new(name: 'Testy Tester', age: 24, employee_id: 1234, department: 'IT')

    expect(emp[:test]).to be_an_instance_of Time
  end

  it 'should accept a proc for a default value' do
    emp = Friend.new(name: 'Testy Tester', age: 24)

    expect(emp[:test]).to be_an_instance_of DateTime
  end

  describe '#===' do
    it 'returns true if the other object includes all of this objects required attributes' do
      person = Person.new(name: 'Jane', age: 23)

      expect(person === { name: 'Jane', age: 23 }).to be true
    end
  end

  describe '#to_hash' do
    it 'returns a duplicated version of the decorated hash' do
      person = Person.new(name: 'Testing', age: 12)

      internal = person.instance_variable_get(:@hash)
      external = person.to_hash

      expect(external).to be_an_instance_of Hash
      expect(external.keys).to eq person.keys
      expect(external.values).to eq person.values

      expect(internal.object_id).not_to eq external.object_id
    end
  end

  describe '#except' do
    it 'will return a new HashDelegator if no required attributes are removed' do
      person = Person.new(name: 'Jake', age: 5, favorite_toy: 'Teddy Bear')
      person = person.except(:favorite_toy)

      expect(person).to be_an_instance_of Person
      expect(person).not_to have_key :favorite_toy

      Person.required_attributes.each do |key|
        expect(person).to have_key key
      end
    end

    it 'will return a duplicate Hash if any required attributes are removed' do
      person = Person.new(name: 'Jake', age: 5).except(:age)

      expect(person).to be_an_instance_of Hash
      expect(person).not_to have_key :age
    end
  end

  describe '#slice' do
    it 'will return a new HashDelegator if all required attributes are specified' do
      person = Person.new(name: 'Jake', age: 5, favorite_toy: 'Teddy Bear')
      person = person.slice(:name, :age)

      expect(person).to be_an_instance_of Person
      expect(person).not_to have_key :favorite_toy

      Person.required_attributes.each do |key|
        expect(person).to have_key key
      end
    end

    it 'will return a duplicate Hash if any of the required attrbutes to missing' do
      person = Person.new(name: 'Jake', age: 5).slice(:age)

      expect(person).to be_an_instance_of Hash
      expect(person).not_to have_key :name
    end
  end
end
