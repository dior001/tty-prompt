# frozen_string_literal: true

RSpec.describe TTY::Prompt::Question, "#raw" do
  subject(:question) { described_class.new(TTY::Prompt::Test.new) }

  it "is unset by default" do
    expect(question.raw).to be_nil
    expect(question.raw?).to be_nil
  end

  it "sets raw mode" do
    question.raw(true)
    expect(question.raw).to eq(true)
    expect(question.raw?).to eq(true)
  end
end
