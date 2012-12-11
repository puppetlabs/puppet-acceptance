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
      confused_name, version, arch = host_overrides['platform'].split('-')
      @is_pe    = is_pe
      @name     = name
      @logger   = logger
      defaults  = is_pe? ? PE_DEFAULTS : FOSS_DEFAULTS
      defaults['version'] = version
      defaults['arch']    = arch
      defaults['family']  = get_family( confused_name )
      defaults['release'] = get_release( confused_name, version )

      @defaults = defaults.merge(config_overrides).merge(host_overrides)
    end

    def get_release maybe_an_os, version
      case maybe_an_os
      when /debian/
        return 'lenny'    if version == '5'
        return 'squeeze'  if version == '6'
        return 'wheezy'   if version == '7'
      when /ubuntu/
        return 'hardy'    if version =~ /8\.04/
        return 'lucid'    if version =~ /10\.04/
        return 'maverick' if version =~ /10\.10/
        return 'natty'    if version =~ /11\.04/
        return 'oneiric'  if version =~ /11\.10/
        return 'precise'  if version =~ /12\.04/
        return 'quantal'  if version =~ /12\.10/
      when /el/
        return '5-6'      if version == '5'
        return '6-6'      if version == '6'
      else
        return version
      end
    end
  end
end
