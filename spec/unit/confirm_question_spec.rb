# frozen_string_literal: true

RSpec.describe TTY::Prompt::ConfirmQuestion do
  subject(:prompt) { TTY::Prompt::Test.new }

  describe "#negative?" do
    it "is false when no :negative option is given" do
      question = described_class.new(prompt)
      expect(question.negative?).to eq(false)
    end

    it "is true when a :negative option is given" do
      question = described_class.new(prompt, negative: "nope")
      expect(question.negative?).to eq(true)
    end
  end
end
