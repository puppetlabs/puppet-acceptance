require 'lib/puppet_acceptance/dsl/install_utils'
# ^^ Do I really need to do this?

test_name 'Create Local Packages if Necessary' do
  extend PuppetAcceptance::DSL::InstallUtils
  # ^^ We have to 'extend' because we are technically already in an instance
  # of TestCase, not in a class definition (`include` is a private method)

  tmp_uris = []

  step 'Extract information from repos URI' do
    options[:install].each do |uri|
      step "Extracting info for #{uri}" do
        tmp_uris << extract_repo_info_from( uri )
      end
    end
  end

  step 'Order packages' do
    package_info = order_packages( tmp_uris )
  end

  step 'Clone git repositories' do
    hosts.each do |host|
      clone_git_repos host, SourcePath, package_info
    end
  end

  step 'Create local packages' do
    create_packages_for_hosts hosts, SourcePath,
                              package_info.map {|p| p[:name] }
  end

  step 'Install local packages' do
    package_info.each do |package|
      hosts.each do |host|
  end
end
