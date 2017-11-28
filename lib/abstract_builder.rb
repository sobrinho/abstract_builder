class AbstractBuilder
  @@format_key = nil
  @@ignore_value = nil

  def self.format_key!(&block)
    @@format_key = block
  end

  def self.ignore_value!(&block)
    @@ignore_value = block
  end

  def initialize
    @stack = []
    @format_key = @@format_key
    @ignore_value = @@ignore_value
  end

  def format_key!(&block)
    @format_key = block
  end

  def ignore_value!(&block)
    @ignore_value = block
  end

  def set!(key, value)
    @stack << [:set, key, value]
  end

  def merge!(value)
    @stack << [:merge, value]
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

  def data!
    data = {}

    @stack.each do |(command, key, value)|
      case command
      when :set
        key = _format_key(key)
        data[key] = value unless _ignore_value?(value)
      when :merge
        data.merge!(key)
      else
        raise ArgumentError, "Unexpected command: #{command.inspect}"
      end
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

        Received #{args.length - 1} argument#{'s' if args.length > 2} #{block ? "with a block" : "without a block"}.
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
    builder
  end

  def _ignore_value?(value)
    @ignore_value && @ignore_value.call(value)
  end
end
