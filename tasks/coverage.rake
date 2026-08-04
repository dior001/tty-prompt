# frozen_string_literal: true

desc "Measure code coverage"
task :coverage do
  original = ENV.fetch("COVERAGE", nil)
  ENV["COVERAGE"] = "true"
  Rake::Task["spec"].invoke
ensure
  ENV["COVERAGE"] = original
end
