# frozen_string_literal: true

require 'securerandom'
require 'net/http'
require 'json'
require 'etc'

class EdrSimulation
  # set root directory of project for convenience
  ROOT_PATH = File.expand_path(File.dirname(File.dirname(__FILE__)))
  DEFAULT_FILE_DIRECTORY = File.join(
    ROOT_PATH,
    'tmp'
  ).freeze

  attr_reader :logs, :simulation_id

  def initialize
    @logs = {
      executable_processes: [],
      file_processes: [],
      network_processes: []
    }
    # Perhaps this should be a timestamp?
    @simulation_id = rand(10_000)
  end

  # creates file in specified location
  def create_file(directory: DEFAULT_FILE_DIRECTORY, extension: nil)
    filename = "simulation-#{@simulation_id}-#{Time.now.to_i}"
    extension ||= 'txt'

    location = File.join(directory, "#{filename}.#{extension}")
    add_file_process_log(File.path(location), 'create')
    File.new(location, 'w')
  end

  # opens and writes random string to specified file (or creates new file)
  def modify_file(file = nil)
    file ||= create_file

    raise ArgumentError, 'Cannot modify file -- Not Found' unless File.exist? file

    add_file_process_log(File.path(file), 'modify')
    contents = SecureRandom.base64
    File.write(file, contents)

    file
  end

  # deletes specified file (or creates new file)
  def delete_file(file = nil)
    file ||= create_file

    raise ArgumentError, 'Cannot delete file -- Not Found' unless File.exist? file

    add_file_process_log(File.path(file), 'delete')
    File.delete(file)
  end

  # Opens connection to example.com and downloads index page
  def download_data
    uri = URI('https://example.com')
    request_start_time = Time.now
    response = Net::HTTP.get_response(uri)
    contents = response.body

    add_network_process_log(request_start_time, uri, response.content_length)

    file = create_file
    file.puts contents
    file.close
    file
  end

  # runs provided executable in a sub-process
  # VERY DANGEROUS - BE CAREFUL WITH INPUT
  def run_executable(executable: 'echo', args: [''])
    pid = Process.spawn(executable, *args)

    add_executable_process_log(pid, executable, [executable, *args].join(' '))

    Process.wait pid
  end

  # options: Options for running full simulation - all options are optional
  # create_file_location: string - should correspond to an existing directory
  # create_file_extension: string
  # modify_file_location: string - should correspond to an existing file
  # delete_file_location: string - should correspond to an existing file
  # executable: string
  # executable_args: string[]
  def run(options)
    create_file_args = {
      directory: options[:create_file_location],
      extension: options[:create_file_extension]
    }.reject { |_k, val| val.nil? }
    create_file(**create_file_args)

    if options[:modify_file_location]
      modify_file(options[:modify_file_location])
    else
      modify_file
    end

    if options[:delete_file_location]
      delete_file(options[:delete_file_location])
    else
      delete_file
    end

    run_executable_args = {
      executable: options[:executable],
      args: options[:executable_args]
    }.reject { |_k, val| val.nil? }
    run_executable(**run_executable_args)

    download_data

    File.write(logfile, JSON.pretty_generate(@logs))
    "Simulation ##{@simulation_id} complete"
  end

  def logfile
    File.join(ROOT_PATH, 'logs', "edr_simulation_run_#{simulation_id}.json")
  end

  def self.run(options = {})
    new.run options
  end

  private

  def add_log(type, log)
    @logs[type] << {
      timestamp: Time.now,
      process_user: Etc.getlogin,
      process_id: Process.pid,
      process_name: Process.argv0
    }.merge(log)
  end

  def add_file_process_log(filepath, activity_kind)
    add_log(:file_processes, {
              filepath: filepath,
              activity_kind: activity_kind
            })
  end

  def add_network_process_log(start_time, uri, content_length)
    local_ip = Socket.ip_address_list.detect(&:ipv4_private?)
    local_port = if uri.scheme == 'https'
                   Net::HTTP.https_default_port
                 else
                   Net::HTTP.default_port
                 end

    add_log(:network_processes, {
              source_host: uri.host,
              source_port: uri.port,
              destination_host: local_ip.ip_address,
              destination_port: local_port,
              request_protocol: uri.scheme,
              content_length: content_length,
              timestamp: start_time
            })
  end

  def add_executable_process_log(pid, name, command)
    add_log(:executable_processes, {
              process_id: pid,
              command: command,
              process_name: name
            })
  end
end
