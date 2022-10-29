# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

require_relative '../lib/edr_simulation'

RSpec.describe EdrSimulation do
  describe '#createFile' do
    it 'creates file with default location and extension' do
      created_file = EdrSimulation.new.create_file

      expect(File.exist?(created_file.path))
      expect(created_file.path).to include(EdrSimulation::DEFAULT_FILE_DIRECTORY)
      expect(created_file.path).to include('.txt')
    end

    it 'creates file at specified location' do
      target_director = File.join('spec', 'tmp')
      created_file = EdrSimulation.new.create_file(directory: target_director)

      expect(File.exist?(created_file.path))
      expect(created_file.path).to include(target_director)
      expect(File.extname(created_file)).to eq '.txt'
    end

    it 'creates file with specified extention' do
      target_director = File.join('spec', 'tmp')
      target_extenstion = '.json'
      created_file = EdrSimulation.new.create_file(directory: target_director, extension: target_extenstion)

      expect(File.exist?(created_file.path))
      expect(created_file.path).to include(target_director)
      expect(File.extname(created_file)).to eq target_extenstion
    end
  end

  describe 'modify file' do
    it 'opens and writes to provided file' do
      file_path = File.join('tmp', 'modify-file-test.txt')
      test_file = File.new(file_path, 'w')
      expect { EdrSimulation.new.modify_file(test_file) }.to(
        change { File.read(test_file) }
      )
    end

    it 'creates an empty file if none provided' do
      result_file = EdrSimulation.new.modify_file
      expect(File.exist?(result_file)).to eq true
      expect(File.read(result_file)).not_to eq ''
    end

    it 'raises if provided file does not exist' do
      test_file = File.join('tmp', 'modify-file-test-nonexists.txt')
      expect { EdrSimulation.new.modify_file(test_file) }.to(
        raise_error(ArgumentError)
      )
    end
  end

  describe 'delete file' do
    it 'deletes provided file' do
      file_path = File.join('tmp', 'delete-file-test.txt')
      File.new(file_path, 'w')

      EdrSimulation.new.delete_file(file_path)
      expect(File.exist?(file_path)).to eq false
    end

    it 'creates and deletes file if none provided' do
      expect(File).to receive(:delete).and_call_original
      EdrSimulation.new.delete_file
    end

    it 'raises if provided file does not exist' do
      file_path = File.join('tmp', 'delete-file-nonexists.txt')
      expect(File).not_to receive(:delete)
      expect { EdrSimulation.new.delete_file(file_path) }.to raise_error(ArgumentError)
    end
  end

  describe 'download_data' do
    it 'makes http request and saves to file' do
      download_contents = '<document><body><h1>Hey</h1><body><document>'
      expect(Net::HTTP).to receive(:get_response).and_return(
        OpenStruct.new(body: download_contents)
      )

      output_file = EdrSimulation.new.download_data
      output_path = output_file.path

      expect(File.exist?(output_path)).to eq(true)
      expect(File.read(output_path).strip).to eq download_contents
    end
  end

  describe 'run_executable' do
    it 'runs excutable' do
      output_file_path = File.join(EdrSimulation::ROOT_PATH, 'spec', 'tmp', 'run_executable_output.txt')
      EdrSimulation.new.run_executable('touch', [output_file_path])
      expect(File.exist?(output_file_path)).to eq true
    end

    it 'runs executable files' do
      # Eample script echos a string into a file
      # NOTE: this will probs break in powershell
      example_script = File.join(EdrSimulation::ROOT_PATH, 'spec', 'fixtures', 'sample_executable.sh')
      example_script_output = File.join(EdrSimulation::ROOT_PATH, 'spec', 'tmp', 'test-output.txt')
      EdrSimulation.new.run_executable(example_script, [example_script_output])
      expect(File.exist?(example_script_output)).to eq true
    end
  end

  describe 'logging' do
    it 'logs file operations' do
      simulation = EdrSimulation.new
      # delete_file has 2 file operations, create and delete
      simulation.delete_file

      expect(simulation.logs[:file_processes].length).to eq 2
      expect(simulation.logs[:file_processes][0]).to match(
        hash_including(
          timestamp: kind_of(Time),
          process_user: kind_of(String),
          process_id: kind_of(Integer),
          process_name: kind_of(String),
          filepath: kind_of(String),
          activity_kind: kind_of(String)
        )
      )
    end

    it 'logs network operations' do
      simulation = EdrSimulation.new
      # delete_file has 2 file operations, create and delete
      simulation.download_data

      expect(simulation.logs[:network_processes].length).to eq 1
      expect(simulation.logs[:network_processes][0]).to match(
        hash_including(
          timestamp: kind_of(Time),
          process_user: kind_of(String),
          process_id: kind_of(Integer),
          process_name: kind_of(String),
          source_host: kind_of(String),
          source_port: 443,
          destination_host: kind_of(String),
          destination_port: 443,
          request_protocol: 'https',
          content_length: kind_of(Integer)
        )
      )
    end

    it 'logs executable operations' do
      simulation = EdrSimulation.new
      # delete_file has 2 file operations, create and delete
      simulation.run_executable('echo', ['howdy'])

      expect(simulation.logs[:executable_processes].length).to eq 1
      expect(simulation.logs[:executable_processes][0]).to match(
        hash_including(
          timestamp: kind_of(Time),
          process_user: kind_of(String),
          process_id: kind_of(Integer),
          process_name: 'echo',
          command: 'echo howdy'
        )
      )
    end
  end
end
