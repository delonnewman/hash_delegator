require "hash_delegator/version"
require 'set'

# Provides delegation and basic validation for Hashes
class HashDelegator
  class << self
    # Return required attributes or nil
    #
    # @return [Array, nil]
    def required_attributes
      return @required_attributes if @required_attributes

      superclass.required_attributes if superclass.respond_to?(:required_attributes)
    end

    # Specifiy required attributes
    #
    # @param *attributes [Array]
    # @return [HashDelegator]
    def require(*attributes)
      if superclass.respond_to?(:required_attributes) && !superclass.required_attributes.nil?
        @required_attributes = superclass.required_attributes + attributes
      else
        @required_attributes = attributes
      end
      self
    end

    # Specify the default value if the value is a Proc or a block is passed
    # each hash's default_proc attribute will be set.
    #
    # @param value [Object] default value
    # @param &block [Proc] default proc
    # @return [HashDelegator]
    def default(value = nil, &block)
      if block
        @default_value = block
        return self
      end

      case value
      when Proc
        @default_value = value
      else
        @default_value = value
      end
      self
    end

    # Return the default value
    def default_value
      return @default_value if @default_value

      superclass.default_value if superclass.respond_to?(:default_value)
    end

    # Specify the key transformer
    def transform_keys(&block)
      @key_transformer = block
    end

    # Return the key transformer
    def key_transformer
      return @key_transformer if @key_transformer
      
      superclass.key_transformer if superclass.respond_to?(:key_transformer)
    end
  end

  MUTATING_METHODS = Set[
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
    :rehash,
    :replace,
    :initialize_copy,
    :shift,
    :store
  ].freeze

  CLOSED_METHODS = Set[
    :compact,
    :merge,
    :except,
    :slice
  ].freeze

  def initialize(hash)
    raise "HashDelegator should not be initialized" if self.class == HashDelegator

    if self.class.key_transformer
      @hash = hash.transform_keys(&self.class.key_transformer)
    else
      @hash = hash.dup
    end

    if Proc === self.class.default_value
      @hash.default_proc = self.class.default_value
    else
      @hash.default = self.class.default_value
    end

    if self.class.required_attributes
      self.class.required_attributes.each do |attribute|
        attribute = self.class.key_transformer.call(attribute) if self.class.key_transformer
        raise "#{attribute.inspect} is required, but is missing" unless key?(attribute)
      end
    end
  end

  def to_hash
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

    if hash_respond_to?(method)
      result = @hash.public_send(method, *args, &block)
      return result unless CLOSED_METHODS.include?(method)
      return self.class.new(result)
    end

    raise NoMethodError, "undefined method `#{method}' for #{self}:#{self.class}"
  end

  private

  def hash_respond_to?(method)
    !MUTATING_METHODS.include?(method) && @hash.respond_to?(method)
  end
end
