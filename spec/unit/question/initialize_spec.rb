# frozen_string_literal: true

RSpec.describe TTY::Prompt::Question, "#initialize" do
  subject(:question) { described_class.new(TTY::Prompt::Test.new) }

  it { expect(question.echo).to eq(true) }

  it { expect(question.modifier).to eq([]) }

  it { expect(question.validation).to eq(TTY::Prompt::Question::UndefinedSetting) }
end

RSpec.describe TTY::Prompt::Question::UndefinedSetting do
  it "converts to a descriptive string" do
    expect(described_class.new.to_s).to eq("undefined")
  end

  it "inspects as a descriptive string" do
    expect(described_class.new.inspect).to eq("undefined")
  end
end
