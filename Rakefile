require "bundler/gem_tasks"
require "rake/testtask"


Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

namespace :test do

  desc "tests for adapters"
  task :adapters do
    Bundler.with_original_env do
      Dir.chdir File.dirname(__FILE__) do
        tests = FileList["test/**/*_adaptertest.rb"].reduce('') do |m, i|
          m << "require './#{i}';"
        end
        exec 'ruby',  '-I"lib:test"', '-e', tests
      end
    end
  end

  desc "run all tests"
  task :all do
    Bundler.with_original_env do
      Dir.chdir File.dirname(__FILE__) do
        tests = FileList["test/**/*_adaptertest.rb", "test/**/*_test.rb"].reduce('') do |m, i|
          m << "require './#{i}';"
        end
        exec 'ruby',  '-I"lib:test"', '-e', tests
      end
    end
  end

end

task :default => :test
