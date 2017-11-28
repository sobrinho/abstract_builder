class AbstractBuilder
  class LazyCache
    def initialize(driver)
      @cache = Hash.new { |h, k| h[k] = {} }
      @driver = driver
    end

    def add(key, options, &block)
      cache[options][key] = block
    end

    def resolve
      resolved = []

      # Fail-fast if there is no items to be computed.
      return resolved if cache.empty?

      # We can't add new items during interation, so iterate through a clone
      # that will allow us to add new items.
      previous = cache.clone
      cache.clear

      # Keys are grouped by options and because of that, fetch_multi will use
      # the same options for the same group of keys.
      previous.each do |options, group|
        result = driver.fetch_multi(*group.keys, options) do |group_key|
          [group[group_key].call, *resolve]
        end

        # Since the fetch_multi returns { cache_key => value }, we need to
        # discard the cache key and merge only the values.
        resolved.concat result.values.flatten(1)
      end

      resolved
    end

    private

    attr_reader :cache, :driver
  end
end
