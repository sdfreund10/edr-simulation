# frozen_string_literal: true

require 'securerandom'
require 'net/http'

class EdrSimulation
  # set root directory of project
  ROOT_PATH = File.expand_path(File.dirname(File.dirname(__FILE__)))
  DEFAULT_FILE_DIRECTORY = File.join(
    ROOT_PATH,
    'tmp'
  ).freeze

  attr_reader :logs

  def initialize(options = {})
    @options = options

    @logs = {
      executable_processes: [],
      file_processes: [],
      network_processes: []
    }
  end

  def create_file(directory: DEFAULT_FILE_DIRECTORY, extension: nil)
    filename = "#{Time.now.to_i}-#{rand(10_000)}"
    extension ||= '.txt'

    location = File.join(directory, filename + extension)
    add_file_process_log(File.path(location), 'create')
    File.new(location, 'w')
  end

  def modify_file(file = nil)
    file ||= create_file

    raise ArgumentError, 'Cannot modify file -- Not Found' unless File.exist? file

    add_file_process_log(File.path(file), 'modify')
    contents = SecureRandom.base64
    File.write(file, contents)

    file
  end

  def delete_file(file = nil)
    file ||= create_file

    raise ArgumentError, 'Cannot delete file -- Not Found' unless File.exist? file

    add_file_process_log(File.path(file), 'delete')
    File.delete(file)
  end

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

  # VERY DANGEROUS - BE CONFIDENT OF INPUT
  def run_executable(executable, args = [])
    pid = Process.spawn(executable, *args)

    add_executable_process_log(pid, executable, [executable, *args].join(' '))

    Process.wait pid
  end

  private

  def add_log(type, log)
    @logs[type] << {
      timestamp: Time.now,
      process_user: Etc.getlogin,
      process_id: Process.pid,
      process_name: Process.argv0,
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
