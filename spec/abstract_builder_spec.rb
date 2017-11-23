RSpec.describe AbstractBuilder do
  describe "#set!" do
    it "sets the key and value" do
      subject.set! :key, "value"

      expect(subject.data!).to eq(key: "value")
    end
  end

  describe "#format_key!" do
    it "formats the key" do
      subject.format_key! { |key| key.upcase }
      subject.set! :key, "value"

      expect(subject.data!).to eq(KEY: "value")
    end
  end

  describe "#ignore_value!" do
    it "ignores the value if the block yields to true" do
      subject.ignore_value! { |value| value.nil? }

      subject.set! :absence, nil
      subject.set! :presence, true

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
      called = false

      subject.block! :meta do |meta|
        called = true

        meta.set! :key, "value"
      end

      expect(called).to be false
      expect(subject.data!).to eq(meta: { key: "value" })
      expect(called).to be true
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
      }.to raise_error(ArgumentError, /Expected 1 argument without a block, 0 arguments with a block or 1 argument with a block.+Received 2 arguments with a block./m)
    end
  end
end
