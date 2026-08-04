# frozen_string_literal: true

RSpec.describe TTY::Prompt::Const::Undefined do
  it "converts to a descriptive string" do
    expect(described_class.to_s).to eq("undefined")
  end

  it "inspects as a descriptive string" do
    expect(described_class.inspect).to eq('"undefined"')
  end
end
