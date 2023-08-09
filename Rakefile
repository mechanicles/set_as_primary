# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

ADAPTERS = %w[postgresql mysql sqlite].freeze

ADAPTERS.each do |adapter|
  namespace :test do
    Rake::TestTask.new(adapter) do |t|
      t.description = "Run #{adapter} tests"
      t.libs << "test"
      t.test_files = FileList["test/#{adapter}_test.rb"]
    end
  end
end

desc "Run all tests"
task :test do
  ADAPTERS.each do |adapter|
    Rake::Task["test:#{adapter}"].invoke
  end
end

task default: :test
