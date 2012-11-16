require 'pathname'

module PuppetAcceptance
  module DSL
    module InstallUtils

      SourcePath  = "/opt/puppet-git-repos"
      GitURI       = %r{^(git|https?)://|^git@}
      GitHubSig   = 'github.com,207.97.227.239 ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ=='
      InsecureBuilderKey = '-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAyEY5yggStAuwY52qJDTsl4vGM5b5Ewp0U6pnDqR7jY0pdJzS
1Rzhv3qqb1Wc/5pAJ5Z69qAayJ4pb/qJPRvgaMDeyHXbYF0/LjUR0WCzgfhCXXvi
kAfXUgQZHjHAH+gLB1olr8BgCSBmzynYu0D1BnSul+7MjELbIK5n5cSg8KWJfsC9
VFQeXiQmMw230gdcTCWeWrhAQFrA3d0PinYd2AloWN5wrvTAhY9rAzbMTdNV/vOL
pP1g81SEIXhfpwDBtVU/OmfwSoCmqr3byjVJWLrQhGYVXp1PbrbUcYsQRfUnjlKe
gOINCpfaOQpNvxrCABR6d+J27qg5MyC8TGpZvwIDAQABAoIBAQCgu+vpf60zHyaD
7Kf+wxMXVbDO+t4QMBXIiDyJ/ezDYIXi93ImZDWyLcrX7AhDBBN1Mkqh4UFdvcJY
AuVeTB9BM3oZvK1Cm9P3S9RvDINFTnBFAwaEviZLxso594fQk7U2Q113vpfU+1JH
9bfiIXIFqmPtwFQeRhIEGrV8LOFWALmhf2/okI8HKPv4wIuJtiyVoTSivGNcqwtq
HjSCUAaJ8AM9o1DB02CGU4OdUF6mi+D+EOH5/lLs/PFF0rb/2rfSghowpfRsSf45
09hA2FnjjiULpvXMomNGwUmlJoYJvSUAPsB2XtLonYqHygNc33RsryIa+2/pV/s9
bvQD6WHRAoGBAOwSHRueFQieFHfKSj7Lk98JFBF1RiEqGk9ItsfYAmXZoIVU175d
RqwGiV//e2Ad0AZ4dTDdueJI5zrAW6WA2dB9paJFq4fykkr1jsklnt18suGDH9w6
1eUl6INaejqaV5CCVJSJIMLv4X4+oXftDFJUbytLLdcF1dFJs2jHZMq7AoGBANku
faRXEqF8d4K2sXGOzLOv2XDrobshgyHiCrqs0DWEQJ7PUA04pxbVdpSdBE2FNEQn
9J2Fhu3N95bKswJ2MqnwCuWqud8Zg2fs0IYnysSxwVGYE6CgSdCpy3tuiVucoP5P
cR+BDz6Z6rRMxxr/TAmnwRO/KLNkv6eseu/2sObNAoGBALRRRbCRuElDziiN+NYs
U//aBF0tcerlKQGEbjEJ2xMG/2i4nK6IuvGtcINGN2v8eahnnEQ+KL0iqJSk15v8
ZuOtBbaEdvg5nerp1C3qsYVGubAto0lqG3WT1h13H8Phnp8AHjDy6XZdGqV+m4Fq
LK46VkwAebwzddYN8J9JJsD/AoGAET36pZhwFzf9ePguIDjZEY7tcWSTo3qmoYMD
nQxpP0ZvpuwIi/Qqd8qcrnHEzK69loehiPv32VtXw7X1/kUKAqnXA6LJPOgWoaKQ
b4YrN/Bwy5yKOl9fXNyOFg+Rgh9uPKJr9bdWUX8Avi22RPNtwvp5fqrXfV6LRLGR
1Qk9xCUCgYA15Br9orArXBVbpzzow39KHrH//w24+oz3Y13QjjgKDHaTpk4IYmwf
X9fs6sZVlQnHNX23VqLM+GBH8DjTShq6T1haNsCqB4qW/gHiN+5Y2V8BjWs/oqCo
KLKxNExBwqU6A1MNbK60lNVzUpfC5MwU9FuZ6L71Y+CyUIAzZRpgwQ==
-----END RSA PRIVATE KEY-----'

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

      def install_packages_for host, base_path, array_of_pkg_info
        array_of_pkg_info.each do |pkg_info|
          install_package_for host, base_path, pkg_info
        end
      end

      def install_package_for host, base_path, pkg_info
        pkgs     = case pkg_info[:name]
                   when /puppet$/
                     if host['roles'].include?( 'master' )
                       return [ 'puppet', 'puppet-common', 'puppetmaster-common', 'puppetmaster-passenger' ] if host['family'] =~ /deb/i
                       return [ 'puppet', 'puppet-server' ] if host['family'] =~ /el/i
                     else
                       return [ 'puppet', 'puppet-common' ] if host['family'] =~ /deb/i
                       return [ 'puppet' ] if host['family'] =~ /el/i
                     end
                   else
                     raise "I don't know what packages to install for #{pkg_info[:name]}"
                   end

        pkg_path = "#{base_path}/#{pkg_info[:name]}/pkg/#{host['family']}/#{host['release']}"
        pkg_cmd  = case host['family']
                   when /deb/i
                     'dpkg -i'
                   when /el/i
                     'yum localinstall'
                   else
                     raise ArgumentError,
                       "I don't know how to install that package"
                   end

        on host, "cd #{pkg_path}; #{pkg_cmd} #{pkgs.join}"
        if host['family'] =~ /deb/i
          on host, 'apt-get -fy install'
        end

      end

      def create_packages_for host, base_path, repo_names
        repo_names.each do |name|
          create_package_for host, "#{base_path}/#{name}"
        end
      end

      # Brizoken
      def create_package_for host, path_to_repository
        package_cmd = case host['family']
                      when /deb/i
                        "export COW=base-#{host['release']}-i386.cow; " +
                        'rake pl:remote_deb_rc'
                      when /el/i
                        "export MOCK=pl-#{host['release'].split('-')[0]}-i386; " +
                        'rake pl:remote_mock_rc'
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
