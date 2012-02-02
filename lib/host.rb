class Host
  def self.create(name, overrides, defaults)
    case overrides['platform']
    when /windows/;
      Windows::Host.new(name, overrides, defaults)
    else
      Unix::Host.new(name, overrides, defaults)
    end
  end

  # A cache for active SSH connections to our execution nodes.
  def initialize(name, overrides, defaults)
    @name,@overrides,@defaults = name,overrides,defaults
  end
  def []=(k,v)
    @overrides[k] = v
  end
  def [](k)
    @overrides.has_key?(k) ? @overrides[k] : @defaults[k]
  end
  def to_str
    @name
  end
  def to_s
    @name
  end
  def +(other)
    @name+other
  end

  attr_reader :name, :overrides


  # general purpose hook for initializing test-specific state prior to executing a test
  def before_test(test_file)
    @current_test_file = test_file
    # reset the state variable for our current test's temporary directory path
    @current_test_tmp_dir = nil
  end

  # general purpose hook for cleaning up test-specific state after executing a test
  def after_test(test_file, test_status)
    begin
      # if the test was successful, and if it created a test-specific temp dir during execution,
      # we'll delete the temp dir
      case test_status
        when :pass
          if @current_test_tmp_dir then
            rm_rf(@current_test_tmp_dir)
          end
      end
    ensure
      @current_test_file = nil
      @current_test_tmp_dir = nil
    end
  end


  # Create a file on the host.
  # Parameters:
  # [file_path] the path to the file to be created
  # [file_content] a string containing the contents to be written to the file
  # [options] a hash containing additional behavior options.  Currently supported:
  # * :mkdirs (default false) if true, attempt to create the parent directories on the remote host before writing
  #       the file
  # * :owner (default 'root') the username of the user that the file should be owned by
  # * :group (default 'puppet') the name of the group that the file should be owned by
  # * :mode (default '644') the mode (file permissions) that the file should be created with
  def create_file(file_path, file_content, options = {})

    default_options = {
        :mkdirs => false,
        :owner => "root",
        :group => "puppet",
        :mode => "644"
    }

    options = default_options.merge(options)


    if (options[:mkdirs] == true) then
      mkdirs(File.dirname(file_path))
    end

    Tempfile.open 'puppet-acceptance' do |tempfile|
      File.open(tempfile.path, 'w') { |file| file.puts file_content }


      do_scp(tempfile.path, file_path)
      chown(options[:owner], options[:group], file_path)
      chmod(options[:mode], file_path)
    end
  end


  # Create a temp file for the current test; basically, this just calls create_file(), but prepends
  # the path to the current test's temp dir onto the file_rel_path parameter.  Thus, the file will
  # be accessible at a well-known relative path for the duration of the test, but will be eligible
  # for automatic cleanup when the test completes because it is located inside of the test's temp
  # dir.
  #
  # See docs for #create_file()
  def create_test_file(file_rel_path, file_content, options = {})
    create_file(get_test_file_path(file_rel_path), file_content, options)
  end

  # Check for the existence of a temp file for the current test; basically, this just calls file_exists?(),
  # but prepends the path to the current test's temp dir onto the file_rel_path parameter.  This allows
  # tests to be written using only a relative path to specify file locations, while still taking advantage
  # of automatic temp file cleanup at test completion.
  #
  # See docs for, e.g., Unix::File.file_exists?()
  def test_file_exists?(file_rel_path)
    file_exists?(get_test_file_path(file_rel_path))
  end

  # Given a relative path, returns an absolute path for a test file.  Basically, this just prepends the
  # a unique temp dir path (specific to the current test execution) to your relative path.
  def get_test_file_path(file_rel_path)
    File.join(test_tmpdir(), file_rel_path)
  end

  # get a temp dir that is unique for the currently executing test
  def test_tmpdir()
    unless (@current_test_tmp_dir) then
      @current_test_tmp_dir = tmpdir(File.basename(@current_test_file, File.extname(@current_test_file)))
    end
    @current_test_tmp_dir
  end


  # Wrap up the SSH connection process; this will cache the connection and
  # allow us to reuse it for each operation without needing to reauth every
  # single time.
  def ssh
    tries = 1
    @ssh ||= begin
               Net::SSH.start(self, self['user'], self['ssh'])
             rescue
               tries += 1
               if tries < 4
                 puts "Try #{tries} -- Host Unreachable"
                 puts 'Trying again in 20 seconds'
                 sleep 20
                 retry
               end
             end
  end

  def close
    if @ssh
      @ssh.close
    end
  end

  def do_action(verb,*args)
    result = Result.new(self,args,'','',0)
    Log.debug "#{self}: #{verb}(#{args.inspect})"
    yield result unless $dry_run
    result
  end

  def exec(command, options)
    do_action('RemoteExec',command) do |result|
      ssh.open_channel do |channel|
        if options[:pty] then
          channel.request_pty do |ch, success|
            if success
              puts "Allocated a PTY on #{@name} for #{command.inspect}"
            else
              abort "FAILED: could not allocate a pty when requested on " +
                "#{@name} for #{command.inspect}"
            end
          end
        end

        channel.exec(command) do |terminal, success|
          abort "FAILED: to execute command on a new channel on #{@name}" unless success
          terminal.on_data                   { |ch, data|       result.stdout << data }
          terminal.on_extended_data          { |ch, type, data| result.stderr << data if type == 1 }
          terminal.on_request("exit-status") { |ch, data|       result.exit_code = data.read_long  }

          # queue stdin data, force it to packets, and signal eof: this
          # triggers action in many remote commands, notably including
          # 'puppet apply'.  It must be sent at some point before the rest
          # of the action.
          terminal.send_data(options[:stdin].to_s)
          terminal.process
          terminal.eof!
        end
      end
      # Process SSH activity until we stop doing that - which is when our
      # channel is finished with...
      ssh.loop
    end
  end

  def do_scp(source, target)
    do_action("ScpFile",source,target) { |result|
      # Net::Scp always returns 0, so just set the return code to 0 Setting
      # these values allows reporting via result.log(test_name)
      result.stdout = "SCP'ed file #{source} to #{@host}:#{target}"
      result.stderr=nil
      result.exit_code=0
      recursive_scp='false'
      recursive_scp='true' if File.directory? source
      ssh.scp.upload!(source, target, :recursive => recursive_scp)
    }
  end
end

require 'lib/host/windows'
require 'lib/host/unix'
