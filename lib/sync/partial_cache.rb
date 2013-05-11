module Sync
  class PartialCache
    def self.for(cache)
      if cache.respond_to? :call
        new(TransformKeyGenerator.new(cache), Rails.cache)
      elsif cache
        new(KeyGenerator.new, Rails.cache)
      else
        NoCache.new
      end
    end

    attr_reader :key_generator, :store

    def initialize(key_generator, store)
      @key_generator = key_generator
      @store = store
    end

    def key_for(partial)
      key_generator.key_for(partial)
    end

    def fetch(partials, &block)
      keys = partials.map { |partial| key_for(partial) }
      result = store.read_multi(*keys)

      partials.each_with_index.map do |partial, index|
        key = keys[index]
        result.fetch(key) do
          block.call(partial).tap { |result| store.write(key, result) }
        end
      end
    end

    class KeyGenerator
      def key_for(partial)
        partial.cache_key
      end
    end

    class TransformKeyGenerator
      attr_reader :transform

      def initialize(transform)
        @transform = transform
      end

      def key_for(partial)
        partial.cache_key(transform)
      end
    end

    class NoCache
      def fetch(partials)
        partials.map { |partial| yield partial }
      end
    end
  end
end
