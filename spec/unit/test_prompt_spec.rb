# frozen_string_literal: true

RSpec.describe TTY::Prompt::Test do
  subject(:prompt) { described_class.new }

  describe "StringIOExtensions#ioctl" do
    it "duck-types IO#ioctl with a fixed terminal width" do
      expect(prompt.input.ioctl(:fake_request, +"buf")).to eq(80)
    end
  end
end
