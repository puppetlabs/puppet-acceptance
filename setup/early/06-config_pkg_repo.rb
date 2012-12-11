
test_name "Config Packing Repository"

skip_test "Skipping Config Packing Repository" unless options[:pkg_repo]

# Currently, this is specific to Linux
confine :except, :platform => 'windows'

aptcfg = %q{ Acquire::http::Proxy "http://proxy.puppetlabs.lan:3128/"; }
ips_pkg_repo="http://solaris-11-internal-repo.acctest.dc1.puppetlabs.net"
debug_opt = options[:debug] ? 'vh' : ''

def puppetlabs_repo_url host
  if host['family'] =~ /el/i
    pkg  = "puppetlabs-release-#{host['release']}.noarch.rpm"
    base = "http://yum.puppetlabs.com/el"
    blah = "#{host['version']}/products/#{host['arch']}"
    url  = "#{base}/#{blah}/#{pkg}"
    logger.debug "These are the return values for puppetlabs_repo_url: #{url} and #{pkg}"
    return [ pkg, url ]
  elsif host['family'] =~ /deb/i
    pkg  = "puppetlabs-release-#{host['release']}.deb"
    base = "http://apt.puppetlabs.com"
    url  = "#{base}/#{pkg}"
    logger.debug "These are the return values for puppetlabs_repo_url: #{url} and #{pkg}"
    return [ pkg, url ]
  else
    logger.warn "Could not find info for host family: #{host['family']}"
  end
end

def epel_info_for! host
  if host['version'] == '6'
    pkg = 'epel-release-6-7.noarch.rpm'
    url = "http://mirror.itc.virginia.edu/fedora-epel/6/i386/#{pkg}"
  elsif host['version'] == '5'
    pkg = 'epel-release-5-4.noarch.rpm'
    url = "http://archive.linux.duke.edu/pub/epel/5/i386/#{pkg}"
  else
    fail_test "I don't understand Enterprise Linux version: #{host['version']}"
  end
  return url
end

hosts.each do |host|
  case
  when host['platform'] =~ /ubuntu/
    on( host, 'if test -f /etc/apt/apt.conf; ' +
              'then mv /etc/apt/apt.conf /etc/apt/apt.conf.bk; ' +
              'fi'
      )
    create_remote_file host, '/etc/apt/apt.conf', aptcfg

    pkg, url = puppetlabs_repo_url( host )
    on( host, "cd /tmp; wget #{url}; dpkg -i #{pkg}" ) if
       on( host,
          'dpkg-query -W puppetlabs-release',
          :acceptable_exit_codes => [0,1]
         ).exit_code == 1

    on host, "apt-get -y -f -m update"

  when host['platform'] =~ /debian/
    pkg, url = puppetlabs_repo_url( host )
    on( host, "cd /tmp; wget #{url}; dpkg -i #{pkg}" ) if
       on( host,
          'dpkg-query -W puppetlabs-release',
          :acceptable_exit_codes => [0,1]
         ).exit_code == 1

    on host, "apt-get -y -f -m update"

  when host['platform'] =~ /solaris-11/
    on host, "/usr/bin/pkg unset-publisher solaris || :"
    on host, "/usr/bin/pkg set-publisher -g #{ips_pkg_repo} solaris"

  when host['platform'] =~ /el-/
    metadata_modified = false

    if on( host,
           'rpm -qa | grep epel-release',
           :acceptable_exit_codes => [0,1] ).exit_code == 1

      metadata_modified = true
      url = epel_info_for! host
      on host, "rpm -i#{debug_opt} #{url}"
    end

    pkg, url = puppetlabs_repo_url( host )
    pl_repo_installed = on( host, "rpm -i#{debug_opt} #{url}",
                            :acceptable_exit_codes => [0,1] )
    metadata_modified = true if pl_repo_installed.exit_code == 0

    on( host, 'yum clean metadata' ) if metadata_modified

  else
    logger.notify "#{host}: repository configuration not modified"

  end
end

