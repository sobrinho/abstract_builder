require 'abstract_builder/null_cache'
require 'abstract_builder/lazy_cache'

class AbstractBuilder
  @@format_key = nil
  @@ignore_value = nil
  @@cache_store = NullCache.new

  def self.cache_store!(cache_store)
    @@cache_store = cache_store
  end

  def self.format_key!(&block)
    @@format_key = block
  end

  def self.ignore_value!(&block)
    @@ignore_value = block
  end

  def initialize
    @format_key = @@format_key
    @ignore_value = @@ignore_value
    @cache_store = @@cache_store
    @lazy_cache = LazyCache.new(@@cache_store)
    @stack = []
  end

  def format_key!(&block)
    @format_key = block
  end

  def ignore_value!(&block)
    @ignore_value = block
  end

  def cache_store!(cache_store)
    @cache_store = cache_store
    @lazy_cache = LazyCache.new(cache_store)
  end

  def set!(key, value)
    @stack << [key, value]
  end

  def merge!(value)
    value.each_pair do |key, value|
      set! key, value
    end
  end

  def call(object, *keys)
    keys.each do |key|
      set! key, object.public_send(key)
    end
  end

  def block!(key, &block)
    builder = _inherit
    block.call(builder)
    value = builder.data!

    set! key, value
  end

  def array!(key, collection, &block)
    values = collection.map do |item|
      builder = _inherit
      block.call(builder, item)
      builder.data!
    end

    set! key, values
  end

  def cache!(cache_key, options = {}, &block)
    cache_key = _compute_cache_key(cache_key)

    @lazy_cache.add(cache_key, options) do
      builder = _inherit
      block.call(builder)
      builder.data!
    end
  end

  def data!
    data = {}

    @stack.each do |(key, value)|
      key = _format_key(key)
      data[key] = value unless _ignore_value?(value)
    end

    @lazy_cache.resolve.each do |value|
      data.merge!(value)
    end

    data
  end

  def method_missing(*args, &block)
    if args.length == 2 && block
      array!(args[0], args[1], &block)
    elsif args.length == 1 && block
      block!(args[0], &block)
    elsif args.length == 2
      set!(args[0], args[1])
    else
      raise ArgumentError, <<~EOF.chomp
        Expected 1 argument without a block, 0 arguments with a block or 1 argument with a block.

        This is `AbstractBuilder#set!', `AbstractBuilder#block!' or `AbstractBuilder#array!' signatures, example:

            builder.content post.content

            builder.meta do |meta_builder|
              meta_builder.hashtags post.hashtags
            end

            builder.comments post.comments do |comment_builder, comment|
              comment_builder.content comment.content
            end

        Received `#{args[0]}' with #{args.length - 1} argument#{'s' if args.length > 2} #{block ? "with a block" : "without a block"}.
      EOF
    end
  end

  private

  def _format_key(key)
    @format_key ? @format_key.call(key) : key
  end

  def _inherit
    builder = self.class.new
    builder.format_key!(&@format_key)
    builder.ignore_value!(&@ignore_value)
    builder.cache_store!(@cache_store)
    builder
  end

  def _compute_cache_key(key)
    [:abstract_builder, :v1, *key].join("/".freeze)
  end

  def _ignore_value?(value)
    @ignore_value && @ignore_value.call(value)
  end
end
