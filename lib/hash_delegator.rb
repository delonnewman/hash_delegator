require 'hash_delegator/version'
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
    # @param attributes [Array]
    # @return [HashDelegator]
    def required(*attributes)
      @required_attributes =
        if superclass.respond_to?(:required_attributes) && !superclass.required_attributes.nil?
          superclass.required_attributes + attributes
        else
          attributes
        end

      self
    end

    # @deprecated
    def require(*attributes)
      warn 'HashDelegator.require is deprecated'
      required(*attrbutes)
    end

    # Specify the default value if the value is a Proc or a block is passed
    # each hash's default_proc attribute will be set.
    #
    # @param value [Object] default value
    # @param block [Proc] default proc
    # @return [HashDelegator]
    def default(value = nil, &block)
      if block
        @default_value = block
        return self
      end

      if value.is_a?(Proc) && value.lambda? && value.arity != 2
        lambda = value
        value  = ->(*args) { lambda.call(*args.slice(0, lambda.arity)) }
      end

      @default_value = value

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

  # Methods that mutate the internal hash, these cannot be called publicly.
  MUTATING_METHODS = Set[
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

  # Methods that are closed (in the algebraic sense) meaning that
  # they will not remove required keys.
  CLOSED_METHODS = Set[
    :compact,
    :merge
  ].freeze

  EMPTY_HASH = {}.freeze
  private_constant :EMPTY_HASH

  # Initialize the HashDelegator with the given hash.
  # If the hash is not frozen it will be duplicated. If a key transformer
  # is specified the hashes keys will be processed with it (duplicating the original hash).
  # The hash will be validated for the existance of the required attributes (note
  # that a key with a nil value still exists in the hash).
  #
  #
  # @param hash [Hash]
  def initialize(hash = EMPTY_HASH)
    raise 'HashDelegator should not be initialized' if instance_of?(HashDelegator)

    @hash =
      if self.class.key_transformer
        hash.transform_keys(&self.class.key_transformer)
      elsif hash.frozen?
        hash
      else
        hash.dup
      end

    if self.class.default_value.is_a?(Proc)
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

  # If the given keys include any required attributes
  # the hash will be duplicated and except will be called
  # on the duplicated hash. Otherwise a new instance of
  # the HashDelegator will be return without the specified keys.
  #
  # @param keys [Array]
  # @return [Hash, HashDelegator]
  def except(*keys)
    common = keys & self.class.required_attributes

    if common.empty?
      self.class.new(@hash.except(*keys))
    else
      to_hash.except(*keys)
    end
  end

  # If the given keys include all of the required attributes
  # a new HashDelegator will be returned with only the specified keys.
  # Otherwise a internal hash will be duplicated and slice will
  # be called on the duplicated hash.
  #
  # @param keys [Array]
  # @return [Hash, HashDelegator]
  def slice(*keys)
    required = self.class.required_attributes
    common   = keys & required

    if keys.size == common.size && common.size == required.size
      self.class.new(@hash.slice(*keys))
    else
      to_hash.slice(*keys)
    end
  end

  # Return a duplicate of the delegated hash.
  #
  # @return [Hash]
  def to_hash
    @hash.dup
  end
  alias to_h to_hash

  def to_s
    "#<#{self.class} #{@hash.inspect}>"
  end
  alias inspect to_s

  # Return the value associated with the given key. If a key transformer
  # is special the key will be transformed first. If the key is missing
  # the default value will be return (nil unless specified).
  #
  # @param key
  def [](key)
    if self.class.key_transformer
      @hash[self.class.key_transformer.call(key)]
    else
      @hash[key]
    end
  end

  # Return the numerical hash of the decorated hash.
  #
  # @return [Integer]
  def hash
    @hash.hash
  end

  # Return true if the other object has the same numerical hash
  # as this object.
  #
  # @return [Boolean]
  def eql?(other)
    @hash.hash == other.hash
  end

  # Return true if the other object has all of this objects required attributes.
  #
  # @param other
  def ===(other)
    required = self.class.required_attributes

    other.respond_to?(:keys) && (common = other.keys & required) &&
      common.size == other.keys.size && common.size == required.size
  end

  # Return true if the other object is of the same class and the
  # numerical hash of the other object and this object are equal.
  #
  # @param other
  #
  # @return [Boolean]
  def ==(other)
    other.instance_of?(self.class) && eql?(other)
  end

  # Return true if the superclass responds to the method
  # or if the method is a key of the internal hash or
  # if the hash responds to this method. Otherwise return false.
  #
  # @note DO NOT USE DIRECTLY
  #
  # @see Object#respond_to?
  # @see Object#respond_to_missing?
  #
  # @param method [Symbol]
  # @param include_all [Boolean]
  def respond_to_missing?(method, include_all)
    super || key?(method) || hash_respond_to?(method)
  end

  # If the method is a key of the internal hash return it's value.
  # If the internal hash responds to the method forward the method
  # to the hash. If the method is 'closed' retrun a new HashDelegator
  # otherwise return the raw result. If none of these conditions hold
  # call the superclass' method_missing.
  #
  # @see CLOSED_METHODS
  # @see Object#method_missing
  #
  # @param method [Symbol]
  # @param args [Array]
  # @param block [Proc]
  def method_missing(method, *args, &block)
    return @hash[method] if @hash.key?(method)

    if hash_respond_to?(method)
      result = @hash.public_send(method, *args, &block)
      return result unless CLOSED_METHODS.include?(method)

      return self.class.new(result)
    end

    super
  end

  private

  def hash_respond_to?(method)
    !MUTATING_METHODS.include?(method) && @hash.respond_to?(method)
  end

  protected

  # Set the key of the internal hash to the given value.
  #
  # @param key
  # @param value
  def []=(key, value)
    @hash[key] = value
  end
end
