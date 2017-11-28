class AbstractBuilder
  class NullCache
    def fetch(key, _options = nil, &block)
      block.call
    end

    def fetch_multi(*keys, options, &block)
      result = {}

      keys.each do |key|
        result[key] = fetch(key, options) do
          block.call(key)
        end
      end

      result
    end
  end
end
