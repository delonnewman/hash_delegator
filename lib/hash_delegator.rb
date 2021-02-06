#require "hash_delegator/version"

# Provides delegation and basic validation for Hashes
class HashDelegator
  class << self
    @@required_attributes = nil
    def required_attributes
      @@required_attributes
    end

    def require(*attributes)
      if @@required_attributes.nil?
        @@required_attributes = attributes
      else
        @@required_attributes += attributes
      end

      self
    end

    def transform_keys(&block)
      @@key_transformer = block
    end

    @@key_transformer = nil
    def key_transformer
      @@key_transformer
    end

    def [](option)
    end
  end

  MUTATING_METHODS = [
    :[]=,
    :clear,
    :delete,
    :update,
    :delete_if,
    :keep_if,
    :compact!,
    :filter!,
    :merge!,
    :reject!,
    :select!,
    :transform_keys!,
    :transform_values!,
    :default=,
    :default_proc=,
    :compare_by_identity,
    :rehash
  ].reduce(Hash.new(false)) { |h, method| h.merge!(method => true) }.freeze

  def initialize(hash)
    raise "HashDelegator should not be initialized" if self.class == HashDelegator

    @hash = hash
    @hash = @hash.transform_keys(&self.class.key_transformer) if self.class.key_transformer

    if self.class.required_attributes
      self.class.required_attributes.each do |attribute|
        raise "#{attribute.inspect} is required, but is missing" unless key?(attribute)
      end
    end
  end

  def to_h
    @hash
  end

  def to_s
    "#<#{self.class} #{@hash.inspect}>"
  end
  alias inspect to_s

  def [](key)
    if self.class.key_transformer
      @hash[self.class.key_transformer.call(key)]
    else
      @hash[key]
    end
  end

  def respond_to?(method)
    super(method) || key?(method) || hash_respond_to?(method)
  end

  def method_missing(method, *args, &block)
    return @hash[method] if @hash.key?(method)
    return @hash.public_send(method, *args, &block) if hash_respond_to?(method)

    raise NoMethodError, "undefined method `#{method}' for #{self}:#{self.class}"
  end

  private

  def hash_respond_to?(method)
    !MUTATING_METHODS[method] && @hash.respond_to?(method)
  end
end
