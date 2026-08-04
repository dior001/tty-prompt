# frozen_string_literal: true

RSpec.describe TTY::Prompt do
  subject(:prompt) { TTY::Prompt::Test.new }

  describe "#stdin" do
    it "returns the standard input stream" do
      expect(prompt.stdin).to eq($stdin)
    end
  end

  describe "#stdout" do
    it "returns the standard output stream" do
      expect(prompt.stdout).to eq($stdout)
    end
  end

  describe "#stderr" do
    it "returns the standard error stream" do
      expect(prompt.stderr).to eq($stderr)
    end
  end

  describe "#tty?" do
    it "checks whether standard output is a terminal" do
      allow($stdout).to receive(:tty?).and_return(true)

      expect(prompt.tty?).to eq(true)
    end

    it "returns false when standard output isn't a terminal" do
      allow($stdout).to receive(:tty?).and_return(false)

      expect(prompt.tty?).to eq(false)
    end
  end
end
