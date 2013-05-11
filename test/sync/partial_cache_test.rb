require_relative '../test_helper'
require 'mocha/setup'
require 'active_support'

describe Sync::PartialCache do
  describe "when cache is disabled" do
    it "does not cache" do
       cache = Sync::PartialCache.for(false)
       results = cache.fetch([1, 2]) do |partial|
         partial + 1
       end

       assert_equal [2, 3], results

       results = cache.fetch([1, 2]) do |partial|
         partial + 2
       end

       assert_equal [3, 4], results
    end
  end

  describe "when cache is enabled" do
    before do
      Rails.stubs(:cache).returns(ActiveSupport::Cache::MemoryStore.new)
    end

    it "does cache" do
      cached_partial = stub(cache_key: 'cached')
      uncached_partial = stub(cache_key: 'uncached')
      cache = Sync::PartialCache.for(true)

      Rails.cache.write('cached', 'cached result')

      results = cache.fetch([cached_partial, uncached_partial]) do |partial|
        'uncached result'
      end

      assert_equal ['cached result', 'uncached result'], results

      results = cache.fetch([cached_partial, uncached_partial]) do |partial|
        raise "#{partial} should be cached"
      end

      assert_equal ['cached result', 'uncached result'], results
    end

    it "transforms keys if passed a transform" do
      transform = lambda { |x| }
      partial = stub
      partial.stubs(:cache_key).with(transform).returns("transformed")

      cache = Sync::PartialCache.for(transform)

      assert_equal "transformed", cache.key_for(partial)
    end

    it "does not transforms keys if not passed a transform" do
      partial = stub
      partial.stubs(:cache_key).with().returns("not transformed")

      cache = Sync::PartialCache.for(true)

      assert_equal "not transformed", cache.key_for(partial)
    end
  end
end
