# frozen_string_literal: true

RSpec.describe TTY::Prompt::Question do
  subject(:question) { described_class.new(TTY::Prompt::Test.new) }

  describe "#to_s" do
    it "returns the question message" do
      question.instance_variable_set(:@message, "What is your name?")
      expect(question.to_s).to eq("What is your name?")
    end
  end

  describe "#inspect" do
    it "returns a debug representation" do
      question.instance_variable_set(:@message, "What is your name?")
      question.instance_variable_set(:@input, "Piotr")

      expect(question.inspect).to eq(
        "#<TTY::Prompt::Question @message=What is your name?, @input=Piotr>"
      )
    end
  end
end
