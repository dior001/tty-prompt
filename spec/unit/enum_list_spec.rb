# frozen_string_literal: true

RSpec.describe TTY::Prompt::EnumList do
  subject(:prompt) { TTY::Prompt::Test.new }

  describe "#default?" do
    it "is false when no default is set" do
      menu = described_class.new(prompt, default: nil)
      expect(menu.default?).to eq(false)
    end

    it "is true when a default is set" do
      menu = described_class.new(prompt, default: 1)
      expect(menu.default?).to eq(true)
    end
  end

  describe "#validate_defaults" do
    it "raises when the default is unset" do
      menu = described_class.new(prompt, default: nil)
      menu.choice("a")

      expect {
        menu.send(:validate_defaults)
      }.to raise_error(TTY::Prompt::ConfigurationError,
                       "default index must be an integer in range (1 - 1)")
    end
  end
end
