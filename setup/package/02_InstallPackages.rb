require 'lib/puppet_acceptance/dsl/install_utils'
require 'lib/puppet_acceptance/ini_file'

test_name 'Install Packages' do
  extend PuppetAcceptance::DSL::InstallUtils

  packages = hosts.first[:installation_pkgs]

  step 'Install local packages' do
    install_packages_for_hosts hosts,
                               SourcePath,
                               packages
  end

  step "Agents: create basic puppet.conf" do
    master_fqdn = ''
    on master, "facter fqdn" do
      master_fqdn = stdout.chomp
    end

    agents.each do |agent|
      puppetconf = File.join(agent['puppetpath'], 'puppet.conf')

      contents = ''
      on agent, "cat #{puppetconf}" do
        contents = stdout
      end

      agent['puppetconf'] = PuppetAcceptance::IniFile.new( contents )
      agent['puppetconf']['agent'] = Hash.new
      agent['puppetconf']['agent']['server'] = master_fqdn

      on agent, %Q(echo "#{agent['puppetconf'].to_s}" > #{puppetconf})
    end
  end
end
