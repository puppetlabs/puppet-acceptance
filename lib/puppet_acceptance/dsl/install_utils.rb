require 'pathname'

module PuppetAcceptance
  module DSL
    module InstallUtils

      SourcePath  = "/opt/puppet-git-repos"
      GitURI       = %r{^(git|https?)://|^git@}
      GitHubSig   = 'github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=='

      def get_insecure_builder_key
        if File.exists?( "#{ENV['HOME']}/.ssh/insecure_builder_key" )
          return File.read( "#{ENV['HOME']}/.ssh/insecure_builder_key" )
        else
          raise 'Could not find builder key to install on SUT at ~/.ssh/insecure_builder_key'
        end
      end

      def prepare_repo_dirs! host
          on host, "test -d #{path} || mkdir -p #{path}"
      end

      def extract_repo_info_from uri
        project = {}
        repo, rev = uri.split('#', 2)
        project[:name] = Pathname.new(repo).basename('.git').to_s
        project[:path] = repo
        project[:rev]  = rev || 'HEAD'
        return project
      end

      # crude, viscious sorting...
      def order_packages packages_array
        puppet = packages_array.select {|e| e[:name] == 'puppet' }
        puppet_depends = packages_array.select {|e| e[:name] == 'hiera' or e[:name] == 'facter' }
        depends_puppet = packages_array - puppet
        depends_puppet = packages_array - puppet_depends
        [puppet_depends, puppet, depends_puppet].flatten
      end

      def create_packages_for_hosts hosts, base_path, repo_names
        hosts.each do |host|
          create_packages_for host, base_path, repo_names
        end
      end

      def install_packages_for_hosts hosts, base_path, array_of_pkg_info
        hosts.each do |host|
          install_packages_for host, base_path, array_of_pkg_info
        end
      end

      def install_packages_for host, base_path, array_of_pkg_info
        array_of_pkg_info.each do |pkg_info|
          install_package_for host, base_path, pkg_info
        end
      end

      def install_package_for host, base_path, pkg_info
        exit_codes = [ 0 ]
        if host['family'] =~ /deb/i
          exit_codes << 1
        end
        pkg_ext = host['family'] =~ /deb/i ? 'deb' : 'rpm'
        pkg_names    = []
        if host['roles'].include?( 'master' )
          if host['family'] =~ /deb/i
            pkg_names = [ 'puppet', 'puppet-common',
              'puppetmaster-common', 'puppetmaster-passenger' ]
          end
          if host['family'] =~ /el/i
            pkg_names = [ 'puppet', 'puppet-server' ]
          end
        else
          if host['family'] =~ /deb/i
            pkg_names = [ 'puppet', 'puppet-common' ]
          end
          if host['family'] =~ /el/i
            pkg_names = [ 'puppet' ]
          end
        end

        base_pkg_path = "#{base_path}/#{pkg_info[:name]}/pkg"
        pkg_path = ''
        if host['family'] =~ /deb/
          pkg_path = base_pkg_path +
                     '/' + host['family'] +
                     '/' + host['release']
        elsif host['family'] =~ /el/
          pkg_path = base_pkg_path +
                     '/' + host['family'] +
                     '/' + host['release'].split('-')[0] +
                     '/products/' + host['arch']
        end

        pkg_cmd  = case host['family']
                   when /deb/i
                     'dpkg -i'
                   when /el/i
                     'yum localinstall -y'
                   else
                     raise ArgumentError,
                       "I don't know how to install that package"
                   end

        version = ''
        on host, "cd #{pkg_path}; git describe" do
          version = stdout.chomp.split('-')[0]
        end

        pkgs = []
        delim = host['family'] =~ /deb/ ? '_' : '-'
        pkg_names.each do |pkg|
          on host, "cd #{pkg_path}; ls | grep ^#{pkg}#{delim}#{version}.*#{pkg_ext}$" do
            pkgs << stdout.chomp
          end
        end

        on host,
           "cd #{pkg_path}; #{pkg_cmd} #{pkgs.join(' ')}",
           :acceptable_exit_codes => exit_codes

        if host['family'] =~ /deb/i
          on host, 'apt-get --fix-broken --yes --force-yes install'
        end
      end

      def create_packages_for host, base_path, repo_names
        repo_names.each do |name|
          create_package_for host, "#{base_path}/#{name}"
        end
      end

      def create_package_for host, path_to_repository
        package_cmd = case host['family']
                      when /deb/i
                        "export COW=base-#{host['release']}-i386.cow; " +
                        'rake pl:remote_deb_rc_build'
                      when /el/i
                        "export MOCK=pl-#{host['release'].split('-')[0]}-i386; " +
                        'rake pl:remote_mock_final'
                      else
                        raise ArgumentError,
                          "I don't know how to create that package"
                      end

        if on( host,
               'test -f ~/.packaging/builder_data.yml',
               :acceptable_exit_codes => [0,1] ).exit_code == 1
          on host, "cd #{path_to_repository}; rake pl:fetch"
        end

        on host, "cd #{path_to_repository}; #{package_cmd}"
      end

      def clone_git_repos_for_hosts hosts, path, repositories
        repo_names = repositories.map {|r| r[:name] }.join(', ')
        host_names = hosts.map {|h| h.name }.join(', ')
        step "Cloning #{repo_names} for #{host_names}" do

          hosts.each do |host|
            clone_git_repos host, path, repositories
          end

        end
      end

      def clone_git_repos host, path, repositories
        repo_names = repositories.map {|r| r[:name] }.join(', ')
        step "Cloning #{repo_names} for #{host.name}" do
          repositories.each do |repo|
            clone_git_repo host, path, repo
          end
        end
      end

      def clone_git_repo host, path, repository
        name   = repository[:name]
        repo   = repository[:path]
        rev    = repository[:rev]
        target = "#{path}/#{name}"

        step "Clone #{repo} if needed" do
          on host, "test -d #{target} || git clone #{repo} #{target}"
        end

        commands = ["cd #{target}",
                    "remote rm origin",
                    "remote add origin #{repo}",
                    "fetch origin",
                    "clean -fdx",
                    "checkout -f #{rev}"]

        step "Update #{name} and check out revision #{rev}" do
          on host, commands.join(" && git ")
        end
      end

      def install_from_git_repos host, path, names
        names.each do |name|
          install_from_git_repo host, path, name
        end
      end

      def install_from_git_repo host, path, name
        target = "#{path}/#{name}"

        step "Install #{name} on the system"
        # The solaris ruby IPS package has bindir set to /usr/ruby/1.8/bin.
        # However, this is not the path to which we want to deliver our
        # binaries. So if we are using solaris, we have to pass the bin and
        # sbin directories to the install.rb
        install_opts = ''
        install_opts = '--bindir=/usr/bin --sbindir=/usr/sbin' if
          host['platform'].include? 'solaris'

          on host,  "cd #{target} && " +
                    "if [ -f install.rb ]; then " +
                    "ruby ./install.rb #{install_opts}; " +
                    "else true; fi"
      end

      def find_git_repo_versions host, path, repository
        step "Grab version for #{repository[:name]}"
        version = {}
        on host, "cd #{path}/#{repository[:name]} && " +
                  "git describe || true" do
          version[repository[:name]] = result.stdout.chomp
        end
        version
      end

    end
  end
end
