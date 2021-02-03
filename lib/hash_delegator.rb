require "hash_delegator/version"

class HashDelegator
  class << self
    def require(*attributes)
      @required_attributes = attributes
    end

    def required_attributes
      @required_attributes
    end

    def present_all(records)
      records.map(&method(:new))
    end
  end

  extend Forwardable
  delegate [] => :to_h

  def initialize(hash)
    raise "HashDelegator should not be initialized" if self.class == HashDelegator

    @hash = hash

    if self.class.required_attributes
      self.class.required_attributes.each do |attribute|
        raise "#{attribute.inspect} is required, but is missing" unless key?(attribute)
      end
    end
  end

  def to_h
    @hash
  end

  def [](key)
    @hash[key.to_s]
  end

  def key?(key)
    @hash.key?(key.to_s)
  end

  def respond_to?(method)
    super(method) || key?(method)
  end

  def method_missing(method)
    return self[method] if key?(method)

    raise NoMethodError, "undefined method `#{method}' for #{self}:#{self.class}"
  end
end
