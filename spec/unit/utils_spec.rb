# frozen_string_literal: true

RSpec.describe TTY::Utils do
  context "#extract_options" do
    it "extracts the trailing options hash without mutating args" do
      args = ["foo", {bar: "baz"}]
      expect(described_class.extract_options(args)).to eq({bar: "baz"})
      expect(args).to eq(["foo", {bar: "baz"}])
    end

    it "returns an empty hash when the last argument isn't a hash" do
      args = %w[foo bar]
      expect(described_class.extract_options(args)).to eq({})
      expect(args).to eq(%w[foo bar])
    end
  end

  context "#blank?" do
    {
      nil => true,
      "" => true,
      "\n\t\s" => true,
      "    " => true,
      "foo" => false,
      :foo => false
    }.each do |value, result|
      it "detects blank of #{value.inspect} as #{result}" do
        expect(described_class.blank?(value)).to eq(result)
      end
    end
  end

  context "#deep_copy" do
    [
      "",
      ["foo", {bar: "baz"}, :fum, 11]
    ].each do |obj|
      it "copies #{obj.inspect}" do
        copy = described_class.deep_copy(obj)
        expect(obj).to eq(copy)
        expect(obj).not_to equal(copy)
      end
    end
  end
end
