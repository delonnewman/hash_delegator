require 'date'

RSpec.describe HashDelegator do
  it "has a version number" do
    expect(HashDelegator::VERSION).not_to be nil
  end

  class Person < described_class
    require :name, :age
    transform_keys(&:to_sym)
  end

  class Employee < Person
    require :employee_id
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
    default proc { DateTime.now }
  end

  it "should raise an exception if a required attribute is missing" do
    expect { Person.new(:name => 'Tester') }.to raise_error(/age/)
    expect { Person.new(:age => 12) }.to raise_error(/name/)
  end

  it "should respond to all the hash's keys as methods" do
    attributes = { :name => 'Tester', :age => 12, :favorite_comic => "Spiderman" }
    person     = Person.new(attributes)

    attributes.each do |key, value|
      expect(person.public_send(key)).to eq value
    end
  end

  it 'should transform key using the specified transformation' do
    attributes = { 'name' => 'Tester', 'age' => 12, :favorite_comic => "Spiderman" }
    person     = Person.new(attributes)

    attributes.each do |key, value|
      expect(person[key]).to eq value
      expect(person[key.to_s]).to eq value
      expect(person[key.to_sym]).to eq value
    end
  end

  it "should inherit it's key transformer from it's superclass if it's superclass hash specified on and it has not" do
    attributes = { 'name' => 'Testy Tester', 'age' => 24, :employee_id => 1234, :department => "IT" }
    person     = Employee.new(attributes)

    attributes.each do |key, value|
      expect(person[key]).to eq value
      expect(person[key.to_s]).to eq value
      expect(person[key.to_sym]).to eq value
    end
  end

  it "should override it's superclass' key transformer if it has one specified" do
    attributes = { 'name' => 'Testy Tester Testing', 'age' => 54, :employee_id => 12345, :department => "IT", 1 => 2 }
    person     = Manager.new(attributes)

    attributes.each do |key, value|
      expect(person[key]).to eq value
      expect(person[key.to_s]).to eq value
    end
  end

  it "should inherit required attributes from it's super class" do
    expect(Manager.required_attributes).to include(*Employee.required_attributes)
    expect(Employee.required_attributes).to include(*Person.required_attributes)

    expect { Manager.new(:name => "testing", age: 41) }.to raise_error(/employee_id/)
  end

  it "should not respond to any mutable methods" do
    expect { Person.new(:name => "Peter", age: 32).merge!(:employee_id => 345) }.to raise_error(NoMethodError)

    described_class::MUTATING_METHODS.keys.each do |method|
      expect { Person.new(:name => "Janice", age: 21).public_send(method) }.to raise_error(NoMethodError)
    end
  end

  it "should respond to any non-mutating hash methods" do
    person = Person.new(:name => "Peter", age: 32)
    
    expect(person.merge(:employee_id => 345)).to be_an_instance_of Hash

    Hash.instance_methods.each do |method|
      next if described_class::MUTATING_METHODS.key?(method)
      expect(person.respond_to?(method)).to be true
    end
  end

  it "should accept a default value" do
    emp = Employee.new(:name => 'Testy Tester', :age => 24, :employee_id => 1234, :department => "IT")
    
    expect(emp[:test]).to be :sorry
  end

  it "should inherit it's default value from it's superclass" do
    emp = Manager.new(:name => 'Testy Tester', :age => 24, :employee_id => 1234, :department => "IT")
    
    expect(emp[:test]).to be :sorry
  end

  it "should accept a block for a default value" do
    emp = Contractor.new(:name => 'Testy Tester', :age => 24, :employee_id => 1234, :department => "IT")
    
    expect(emp[:test]).to be_an_instance_of Time
  end

  it "should accept a proc for a default value" do
    emp = Friend.new(:name => 'Testy Tester', :age => 24)
    
    expect(emp[:test]).to be_an_instance_of DateTime
  end
end
