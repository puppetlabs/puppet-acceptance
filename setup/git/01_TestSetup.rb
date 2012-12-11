require 'lib/puppet_acceptance/dsl/install_utils'

test_name "Install packages and repositories on target machines..." do
  extend PuppetAcceptance::DSL::InstallUtils

  SourcePath  = PuppetAcceptance::DSL::InstallUtils::SourcePath
  GitURI      = PuppetAcceptance::DSL::InstallUtils::GitURI
  GitHubSig   = PuppetAcceptance::DSL::InstallUtils::GitHubSig

  tmp_repositories = []
  options[:install].each do |uri|
    raise(ArgumentError, "#{uri} is not recognized.") unless(uri =~ GitURI)
    tmp_repositories << extract_repo_info_from(uri)
  end

  repositories = order_packages(tmp_repositories)

  versions = {}
  hosts.each_with_index do |host, index|
    on host, "echo #{GitHubSig} >> $HOME/.ssh/known_hosts"

    clone_git_repos host, SourcePath, repositories
    install_from_git_repos host, SourcePath, repositories.map {|r| r[:name] }

    if index == 1
      repositories.each do |repo|
        versions[repo[:name]] = find_git_repo_versions(host,
                                                       SourcePath,
                                                       repo)
      end
    end
  end

  config[:version] = versions

  step "Agents: create basic puppet.conf" do
    agents.each do |agent|
      puppetconf = File.join(agent['puppetpath'], 'puppet.conf')

      on agent, "echo '[agent]' > #{puppetconf} && " +
                "echo server=#{master} >> #{puppetconf}"
    end
  end
end
