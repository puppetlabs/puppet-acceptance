require 'lib/puppet_acceptance/dsl/install_utils'
# ^^ Do I really need to do this?

test_name 'Create Local Packages if Necessary' do
  extend PuppetAcceptance::DSL::InstallUtils
  # ^^ We have to 'extend' because we are technically already in an instance
  # of TestCase, not in a class definition (`include` is a private method)

  tmp_uris      = []
  packages_info = []

  # Its important to remember that the Hash returned from
  # #extract_repo_info_from() is of the format:
  #  :name => 'repository name, often doubling as project name'
  #  :path => 'uri to repository'
  #  :rev  => 'git revision to checkout'
  step 'Extract information from repos URI' do
    options[:install].each do |uri|
      step "Extracting info for #{uri}" do
        raise(ArgumentError, "#{uri} is not recognized.") unless(uri =~ GitURI)
        tmp_uris << extract_repo_info_from( uri )
      end
    end
  end

  step 'Order packages' do
    packages_info = order_packages( tmp_uris )
  end

  versions = {}
  step 'Clone git repositories' do
    prepare_repo_dirs! hosts
    hosts.each_with_index do |host, index|

      clone_git_repos host, SourcePath, packages_info

      packages_info.each do |repository|
        if index == 1
          versions[repository[:name]] = find_git_repo_versions(host,
                                                               SourcePath,
                                                               repository)
        end
      end
    end
  end

  config[:version] = versions

  step 'Install packaging dependencies' do
    hosts.each do |host|
      on( hosts, 'apt-get install -y rake rsync' ) if host['family'] =~ /deb/i
      on( hosts, 'yum install -y rubygem-rake rsync' ) if host['family'] =~ /^el/i
    end

    packages_info.each do |pkg_info|
      on hosts, "cd #{SourcePath}/#{pkg_info[:name]}; rake package:bootstrap; rake pl:fetch"
    end
  end

  step 'Setup SSH for cloning and bulding' do
    hosts.each do |host|
      if host['family'] =~ /deb/i
        yml_cmd = %q<ruby -e "require 'yaml'; defaults = YAML.load_file( \"#{ENV['HOME']}/.packaging/builder_data.yaml\" ); puts defaults['deb_build_host']" >
      elsif host['family'] =~ /el/i
        yml_cmd = %q<ruby -e "require 'yaml'; defaults = YAML.load_file( \"#{ENV['HOME']}/.packaging/builder_data.yaml\" ); puts defaults['rpm_build_host']" >
      end

      builder_host = ''
      on host, yml_cmd do
        builder_host = stdout.chomp
      end

      if on( host, "cat << 'INSECUREKEY' > $HOME/.ssh/id_rsa
#{get_insecure_builder_key}
INSECUREKEY", :silent => true ).exit_code == 0
        logger.debug "Successfully added insecure builder key"
      end

      on host, 'chmod 600 $HOME/.ssh/id_rsa', :silent => true

      on host, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"
      on host, 'touch ~/.ssh/config'
      on host, "cat << 'SSHCONFIG' > $HOME/.ssh/config
Host #{builder_host}
  HostName #{builder_host}
  User insecure-builder
  StrictHostKeyChecking no
  UserKnownHostsFile=/dev/null
SSHCONFIG", :silent => true

      # This is the greatest thing EVER
      on host, 'mv /etc/ssh/sshd_config /etc/ssh/sshd_config.backup', :silent => true
      on host, 'sed "s/StrictModes yes/StrictModes no/" /etc/ssh/sshd_config.backup >/etc/ssh/sshd_config', :silent => true
    end
  end

  step 'Create local packages' do
    hosts.each do |host|
      packages_info.each do |pkg_info|
        if on( host,
              "test -d #{SourcePath}/#{pkg_info[:name]}/pkg",
              :acceptable_exit_codes => [0,1] ).exit_code == 1
          create_package_for host, "#{SourcePath}/#{pkg_info[:name]}"
        end
      end
    end
  end

  step 'Install local packages' do
    install_packages_for_hosts hosts,
                               SourcePath,
                               packages_info
  end

  step "Agents: create basic puppet.conf" do
    agents.each do |agent|
      puppetconf = File.join(agent['puppetpath'], 'puppet.conf')

      on agent, "echo '[agent]' > #{puppetconf} && " +
                "echo server=#{master} >> #{puppetconf}"
    end
  end
end
