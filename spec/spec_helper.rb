require "bundler/setup"
require "abstract_builder"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

class Person
  def name
    "John Doe"
  end

  def born
    "September 23, 1926"
  end

  protected

  def aged
    40
  end

  private

  def died
    "July 17, 1967"
  end
end

class NaiveCache
  def initialize
    @cache = {}
  end

  def fetch(key, _options, &block)
    @cache[key] ||= block.call
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
