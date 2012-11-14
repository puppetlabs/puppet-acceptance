require File.expand_path(File.join(File.dirname(__FILE__), '..', 'host'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'command_factory'))

module Unix
  class Host < PuppetAcceptance::Host
    require File.expand_path(File.join(File.dirname(__FILE__), 'unix', 'user'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'unix', 'group'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'unix', 'exec'))
    require File.expand_path(File.join(File.dirname(__FILE__), 'unix', 'file'))

    include Unix::User
    include Unix::Group
    include Unix::File
    include Unix::Exec


    PE_DEFAULTS = {
      'user'          => 'root',
      'puppetpath'    => '/etc/puppetlabs/puppet',
      'puppetbin'     => '/opt/puppet/bin/puppet',
      'puppetbindir'  => '/opt/puppet/bin',
      'pathseparator' => ':',
      }

    FOSS_DEFAULTS = {
      'user'              => 'root',
      'puppetpath'        => '/etc/puppet',
      'puppetvardir'      => '/var/lib/puppet',
      'puppetbin'         => '/usr/bin/puppet',
      'puppetbindir'      => '/usr/bin',
      'hieralibdir'       => '/opt/puppet-git-repos/hiera/lib',
      'hierapuppetlibdir' => '/opt/puppet-git-repos/hiera-puppet/lib',
      'hierabindir'       => '/opt/puppet-git-repos/hiera/bin',
      'pathseparator'     => ':',
    }

    def initialize name, config_overrides, host_overrides, logger, is_pe
      @is_pe  = is_pe
      @name   = name
      @logger = logger
      defaults = is_pe? ? PE_DEFAULTS : FOSS_DEFAULTS
      @defaults = defaults.merge(config_overrides).merge(host_overrides)
    end
  end
end
