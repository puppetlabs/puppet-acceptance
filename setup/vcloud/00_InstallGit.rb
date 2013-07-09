test_name "Setup environment"

hosts.each do |host|
  step "Installing git"
  on host, "cmd /c apt-get -y install git-core"
end
