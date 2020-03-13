# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:postgresql) do |t|
  t.libs << "test"
  t.test_files = FileList["test/postgresql_test.rb"]
end

Rake::TestTask.new(:mysql) do |t|
  t.libs << "test"
  t.test_files = FileList["test/mysql_test.rb"]
end

Rake::TestTask.new(:sqlite) do |t|
  t.libs << "test"
  t.test_files = FileList["test/sqlite_test.rb"]
end

task default: [:postgresql, :mysql, :sqlite]
