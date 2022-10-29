# frozen_string_literal: true

require 'pry-byebug'

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # track and delete files created during tests
  config.around(:all) do |example|
    starting_files = Dir.entries('tmp')

    example.run

    added_files = Dir.entries('tmp') - starting_files
    added_files.each { |f| File.delete(File.join('tmp', f)) }
  end

  config.around(:all) do |example|
    directory = File.join('spec', 'tmp')
    starting_files = Dir.entries(directory)

    example.run

    added_files = Dir.entries(directory) - starting_files
    added_files.each { |f| File.delete(File.join(directory, f)) }
  end
end
