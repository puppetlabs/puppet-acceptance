require 'lib/puppet_acceptance/dsl/install_utils'
# ^^ Do I really need to do this?

test_name 'Create Local Packages if Necessary' do
  extend PuppetAcceptance::DSL::InstallUtils
  # ^^ We have to 'extend' because we are technically already in an instance
  # of TestCase, not in a class definition (`include` is a private method)

  tmp_uris = []

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

  step 'Setup SSH for cloning and bulding' do
    hosts.each do |host|
      if host['family'] =~ /deb/i
        yml_cmd = %q<ruby -e "require 'yaml'; defaults = YAML.load_file( '~/.packaging/build_defaults.yml' ); puts defaults['deb_build_host']" >
      elsif host['family'] =~ /el/i
        yml_cmd = %q<ruby -e "require 'yaml'; defaults = YAML.load_file( '~/.packaging/build_defaults.yml' ); puts defaults['deb_build_host']" >
      end

      on host, yml_cmd do |result|
        builder_host = result.stdout.chomp
      end

      on host, "echo #{InsecureBuilderKey} >> $HOME/.ssh/id_rsa"
      on host, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"
      on host, 'touch ~/.ssh/config'
      on host, "echo <<SSHCONFIG
Host #{builder_host}
HostName #{builder_host}
User insecure_builder
SSHCONFIG >> $HOME/.ssh/config"

    end
  end

  versions = {}
  step 'Clone git repositories' do
    hosts.each_with_index do |host, index|

      clone_git_repos host, SourcePath, packages_info

      repositories.each do |repository|
        if index == 1
          versions[repository[:name]] = find_git_repo_versions(host,
                                                               SourcePath,
                                                               repository)
        end
      end
    end
  end

  config[:version] = versions

  step 'Create local packages' do
    create_packages_for_hosts hosts,
                              SourcePath,
                              packages_info.map {|p| p[:name] }
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
