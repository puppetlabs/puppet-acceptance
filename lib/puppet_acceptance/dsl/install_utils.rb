require 'pathname'

module PuppetAcceptance
  module DSL
    module InstallUtils

      SourcePath  = "/opt/puppet-git-repos"
      GitURI       = %r{^(git|https?)://|^git@}
      GitHubSig   = 'github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=='

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

      def create_packages_for host, base_path, repo_names
        repo_names.each do |name|
          create_package_for host, "#{base_path}/#{name}"
        end
      end

      def create_package_for host, path_to_repository
        package_cmd = case host['platform']
                      when /debian/, /ubuntu/
                        'rake package:deb'
                      when /el-/
                        'rake package:rpm'
                      when /windows/
                        'sure....'
                      else
                        raise ArgumentError,
                          'I dont know how to create that package'
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
          on host, "test -d #{path} || mkdir -p #{path}"
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
