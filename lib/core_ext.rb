# frozen_string_literal: true

if RUBY_VERSION.split('.').take(2).join('.').to_f < 3
  class Hash
    def except(*keys)
      h = dup
      keys.each do |key|
        h.delete(key)
      end
      h
    end
  end
end
