RSpec.describe AbstractBuilder::LazyCache do
  it "resolves all entries at once using fetch multi" do
    driver = NaiveCache.new

    expect(driver).to receive(:fetch_multi).with("x", "y", "z", {}).and_call_original.exactly(3).times

    3.times do
      lazy_cache = described_class.new(driver)
      lazy_cache.add("x", {}) { { x: true } }
      lazy_cache.add("y", {}) { { y: true } }
      lazy_cache.add("z", {}) { { z: true } }

      expect(lazy_cache.resolve).to eq [
        { x: true },
        { y: true },
        { z: true }
      ]
    end
  end

  it "resolves all entries at once per options using fetch multi" do
    driver = NaiveCache.new

    expect(driver).to receive(:fetch_multi).with("x", { option: false }).and_call_original.exactly(3).times
    expect(driver).to receive(:fetch_multi).with("y", "z", { option: true }).and_call_original.exactly(3).times

    3.times do
      lazy_cache = described_class.new(driver)
      lazy_cache.add("x", { option: false }) { { x: true } }
      lazy_cache.add("y", { option: true }) { { y: true } }
      lazy_cache.add("z", { option: true }) { { z: true } }

      expect(lazy_cache.resolve).to eq [
        { x: true },
        { y: true },
        { z: true }
      ]
    end
  end

  it 'resolves nested entries at once using fetch multi' do
    driver = NaiveCache.new

    expect(driver).to receive(:fetch_multi).with("x", {}).and_call_original.exactly(3).times
    expect(driver).to receive(:fetch_multi).with("y", "z", { option: false }).and_call_original.exactly(1).times
    expect(driver).to receive(:fetch_multi).with("w", { option: true }).and_call_original.exactly(1).times

    3.times do
      lazy_cache = described_class.new(driver)

      lazy_cache.add("x", {}) do
        lazy_cache.add("y", { option: false }) do
          { y: true }
        end

        lazy_cache.add("z", { option: false }) do
          { z: true }
        end

        lazy_cache.add("w", { option: true }) do
          { w: true }
        end

        { x: true }
      end

      expect(lazy_cache.resolve).to eq [
        { x: true },
        { y: true },
        { z: true },
        { w: true }
      ]
    end
  end
end
