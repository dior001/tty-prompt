# frozen_string_literal: true

RSpec.describe TTY::Prompt, "#debug" do
  subject(:prompt) { TTY::Prompt::Test.new }

  it "prints messages aligned to the top right corner" do
    allow(TTY::Screen).to receive(:width).and_return(20)

    prompt.debug("info1", "info2")

    expect(prompt.output.string).to eq(
      [
        prompt.cursor.save,
        prompt.cursor.column(15) + prompt.cursor.up + prompt.cursor.clear_line_after,
        "info2",
        prompt.cursor.column(15) + prompt.cursor.up + prompt.cursor.clear_line_after,
        "info1",
        prompt.cursor.restore
      ].join
    )
  end

  it "restores the cursor even if printing raises an error" do
    allow(TTY::Screen).to receive(:width).and_return(20)
    allow(prompt).to receive(:print).and_call_original
    allow(prompt).to receive(:print).with("boom").and_raise("boom")

    expect {
      prompt.debug("boom")
    }.to raise_error("boom")

    expect(prompt.output.string).to include(prompt.cursor.restore)
  end
end
