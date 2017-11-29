RSpec.describe AbstractBuilder do
  describe "#format_key!" do
    it "formats the key" do
      subject.format_key! { |key| key.upcase }
      subject.set! :key, "value"

      expect(subject.data!).to eq(KEY: "value")
    end

    it "inherits the global format key by default" do
      begin
        AbstractBuilder.format_key! { |key| key.upcase }

        subject.set! :key, "value"

        expect(subject.data!).to eq(KEY: "value")
      ensure
        AbstractBuilder.format_key!
      end
    end
  end

  describe "#ignore_value!" do
    it "ignores the value if the block yields to true" do
      subject.ignore_value! { |value| value.nil? }

      subject.set! :absence, nil
      subject.set! :presence, true

      expect(subject.data!).to eq(presence: true)
    end

    it "inherits the global ignore value by default" do
      begin
        AbstractBuilder.ignore_value! { |value| value.nil? }

        subject.set! :absence, nil
        subject.set! :presence, true

        expect(subject.data!).to eq(presence: true)
      ensure
        AbstractBuilder.ignore_value!
      end
    end
  end

  describe "#cache_store!" do
    let :cache_store do
      AbstractBuilder::NullCache.new
    end

    it "caches using the given cache store" do
      subject.cache_store! cache_store

      expect(cache_store).to receive(:fetch_multi).with([:abstract_builder, :v1, :cache_key], {}).and_call_original

      subject.cache! :cache_key do |builder|
        builder.cache "hit"
      end

      subject.data!
    end

    it "caches using the given options" do
      subject.cache_store! cache_store

      expect(cache_store).to receive(:fetch_multi).with([:abstract_builder, :v1, :cache_key], option: true).and_call_original

      subject.cache! :cache_key, option: true do |builder|
        builder.cache "hit"
      end

      subject.data!
    end

    it "inherits the global ignore value by default" do
      begin
        AbstractBuilder.cache_store! cache_store

        expect(cache_store).to receive(:fetch_multi).with([:abstract_builder, :v1, :cache_key], {}).and_call_original

        subject.cache! :cache_key do |builder|
          builder.cache "hit"
        end

        subject.data!
      ensure
        AbstractBuilder.cache_store! AbstractBuilder::NullCache.new
      end
    end
  end

  describe "#set!" do
    it "sets the key and value" do
      subject.set! :key, "value"

      expect(subject.data!).to eq(key: "value")
    end
  end

  describe "#merge!" do
    it "merges the given hash" do
      subject.merge! key: "value"

      expect(subject.data!).to eq(key: "value")
    end

    it "formats keys of the given hash" do
      subject.format_key! { |key| key.upcase }

      subject.merge! key: true

      expect(subject.data!).to eq(
        KEY: true
      )
    end

    it "ignores values of the given hash" do
      subject.ignore_value! { |value| value.nil? }

      subject.merge! absence: nil, presence: true

      expect(subject.data!).to eq(presence: true)
    end
  end

  describe "#call" do
    it "extracts the given methods from the given object" do
      person = Person.new

      subject.(person, :name, :born)

      expect(subject.data!).to eq(name: person.name, born: person.born)
    end

    it "do not allows non-public methods" do
      person = Person.new

      expect { subject.(person, :aged) }.to raise_error(NoMethodError, /protected method `aged' called/)
      expect { subject.(person, :died) }.to raise_error(NoMethodError, /private method `died' called/)
    end
  end

  describe "#block!" do
    it "sets the block result as value of the given key" do
      subject.block! :meta do |meta|
        meta.set! :key, "value"
      end

      expect(subject.data!).to eq(meta: { key: "value" })
    end

    it "skips if the block result is empty" do
      subject.block! :meta do |_meta|
      end

      expect(subject.data!).to eq({})
    end

    context "using format key" do
      it "inherits the parent format key" do
        subject.format_key! { |key| key.upcase }

        subject.block! :meta do |meta|
          meta.set! :y, "y"
        end

        expect(subject.data!).to eq(META: { Y: "y" })
      end

      it "do not leaks the format key to the parent" do
        subject.set! :before, true

        subject.block! :meta do |meta|
          meta.format_key! { |key| key.upcase }

          meta.set! :key, "value"
        end

        subject.set! :after, true

        expect(subject.data!).to eq(
          before: true,
          meta: {
            KEY: "value"
          },
          after: true
        )
      end
    end

    context "using ignore value" do
      it "inherits the parent ignore value" do
        subject.ignore_value! { |value| value.nil? }

        subject.set! :absence, nil
        subject.set! :presence, true

        subject.block! :meta do |meta|
          meta.set! :absence, nil
          meta.set! :presence, true
        end

        expect(subject.data!).to eq(
          presence: true,
          meta: {
            presence: true
          }
        )
      end

      it "do not leaks the ignore value to the parent" do
        subject.set! :before, nil

        subject.block! :meta do |meta|
          meta.ignore_value! { |value| value.nil? }

          meta.set! :absence, nil
          meta.set! :presence, true
        end

        subject.set! :after, nil

        expect(subject.data!).to eq(
          before: nil,
          meta: {
            presence: true
          },
          after: nil
        )
      end
    end

    context "using cache store" do
      it "inherits the parent cache store" do
        driver = NaiveCache.new

        # cache miss
        builder = described_class.new
        builder.cache_store! driver

        builder.cache! :outside_cache_key do |builder|
          builder.outside_cache "hit"
        end

        builder.block! :meta do |meta|
          meta.cache! :inside_cache_key do |builder|
            builder.inside_cache "hit"
          end
        end

        expect(builder.data!).to eq(
          outside_cache: "hit",
          meta: {
            inside_cache: "hit"
          }
        )

        # cache hit
        builder = described_class.new
        builder.cache_store! driver

        builder.cache! :outside_cache_key do |builder|
          builder.outside_cache "miss"
        end

        builder.block! :meta do |meta|
          meta.cache! :inside_cache_key do |builder|
            builder.inside_cache "miss"
          end
        end

        expect(builder.data!).to eq(
          outside_cache: "hit",
          meta: {
            inside_cache: "hit"
          }
        )
      end

      it "do not leaks the ignore value to the parent" do
        null_driver = AbstractBuilder::NullCache.new
        naive_driver = NaiveCache.new

        # cache miss
        builder = described_class.new
        builder.cache_store! null_driver

        builder.block! :meta do |meta|
          meta.cache_store! naive_driver

          meta.cache! :inside_cache_key do |builder|
            builder.inside_cache "hit"
          end
        end

        builder.cache! :outside_cache_key do |builder|
          builder.outside_cache "hit"
        end

        expect(builder.data!).to eq(
          meta: {
            inside_cache: "hit"
          },
          outside_cache: "hit"
        )

        # cache hit
        builder = described_class.new
        builder.cache_store! null_driver

        builder.block! :meta do |meta|
          meta.cache_store! naive_driver

          meta.cache! :inside_cache_key do |builder|
            builder.inside_cache "miss"
          end
        end

        builder.cache! :outside_cache_key do |builder|
          builder.outside_cache "miss"
        end

        expect(builder.data!).to eq(
          meta: {
            inside_cache: "hit"
          },
          outside_cache: "miss"
        )
      end
    end
  end

  describe "#array!" do
    it "yields each item to the block and sets the result as value" do
      person = Person.new
      people = [person, person, person]

      subject.array! :people, people do |builder, person|
        builder.set! :name, person.name
        builder.set! :born, person.born
      end

      expect(subject.data!).to eq(
        people: [
          { name: person.name, born: person.born },
          { name: person.name, born: person.born },
          { name: person.name, born: person.born }
        ]
      )
    end
  end

  describe "#cache!" do
    it "caches the given block" do
      driver = NaiveCache.new

      # cache miss
      builder = described_class.new
      builder.cache_store! driver

      builder.cache! :cache_key do |cache|
        cache.cache "hit"
      end

      expect(builder.data!).to eq(cache: "hit")

      # cache hit
      builder = described_class.new
      builder.cache_store! driver

      builder.cache! :cache_key do |cache|
        cache.cache "miss"
      end

      expect(builder.data!).to eq(cache: "hit")
    end
  end

  describe "#method_missing" do
    it "sets the key and value" do
      subject.key "value"

      expect(subject.data!).to eq(key: "value")
    end

    it "sets the block result as value of the given key" do
      subject.meta do |meta|
        meta.key "value"
      end

      expect(subject.data!).to eq(meta: { key: "value" })
    end

    it "yields each item to the block and sets the result as value" do
      person = Person.new
      people = [person, person, person]

      subject.people people do |builder, person|
        builder.name person.name
        builder.born person.born
      end

      expect(subject.data!).to eq(
        people: [
          { name: person.name, born: person.born },
          { name: person.name, born: person.born },
          { name: person.name, born: person.born }
        ]
      )
    end

    it "raises an error on wrong number of arguments" do
      person = Person.new
      people = [person]

      expect {
        subject.people people, invalid_option: true do |builder, person|
          builder.name person.name
        end
      }.to raise_error(ArgumentError, /Expected 1 argument without a block, 0 arguments with a block or 1 argument with a block.+Received `people' with 2 arguments with a block./m)
    end
  end

  describe "inheritance" do
    let(:builder) { Class.new(AbstractBuilder) }
    let(:subject) { builder.new }

    it "blocks uses the same constructor" do
      subject.block! :block do |block|
        expect(block).to be_instance_of builder
      end
    end

    it "arrays uses the same constructor" do
      subject.array! :array, [1, 2, 3] do |array, _item|
        expect(array).to be_instance_of builder
      end
    end
  end
end
