class AbstractBuilder
  class NullCache
    def fetch(key, _options = nil, &block)
      block.call
    end
  end
end
