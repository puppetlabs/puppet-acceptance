module Unix::Pkg
  include PuppetAcceptance::CommandFactory

  def check_for_package name
    result = exec(PuppetAcceptance::Command.new("which #{name}"), :acceptable_exit_codes => (0...127))
    result.exit_code == 0
  end

  def install_package name
    case self['platform']
      when /fedora|centos|el/
        execute("yum -y install #{name}")
      when /ubuntu|debian/
        execute("apt-get update")
        execute("apt-get install -y #{name}")
      when /solaris/
        execute("pkg install #{name}")
      else
        raise "Package #{name} cannot be installed on #{self}"
    end
  end

end
