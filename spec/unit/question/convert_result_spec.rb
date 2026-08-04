# frozen_string_literal: true

RSpec.describe TTY::Prompt::Question, "#convert_result" do
  subject(:question) { described_class.new(TTY::Prompt::Test.new) }

  it "returns the value unchanged when no conversion is configured" do
    expect(question.convert_result("42")).to eq("42")
  end
end
