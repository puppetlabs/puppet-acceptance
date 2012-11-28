# test_name "Puppet Master sanity checks: PID file and SSL dir creation"
#
# pidfile = '/var/lib/puppet/run/master.pid'
#
# with_master_running_on(master, "--dns_alt_names=\"puppet,$(facter hostname),$(facter fqdn)\" --verbose --noop") do
#   # SSL dir created?
#   step "SSL dir created?"
#   on master,  "[ -d #{master['puppetpath']}/ssl ]"
#
#   # PID file exists?
#   step "PID file created?"
#   on master, "[ -f #{pidfile} ]"
# end
#
#
# Agents certs will remain waiting for signing on master until this step
#

step 'Sign Requested Agent Certs'
on(master, puppet("cert --sign --all"), :acceptable_exit_codes => [0,24])

agents.each do |agent|
  next unless agent['roles'].length == 1 and agent['roles'].include?('agent')

  (0..10).each do |i|
    step "Checking if cert issued for #{agent} (#{i})"

    # puppet cert --list <IP> fails, so list all
    break if on(master, puppet("cert --list --all")).stdout =~ /^#{Regexp.escape("+ \"#{agent.name}\"")}/

    fail_test("Failed to sign cert for #{agent}") if i == 10

    step "Wait for agent #{agent}: #{i}"
    sleep 10
    on(master, puppet("cert --sign --all"), :acceptable_exit_codes => [0,24])
  end
end

test_name "Agent --test post install"

agents.each do |agent|
  step "Stopping puppet agent on #{agent}"

  if agent['platform'].include?('solaris')
    on(agent, '/usr/sbin/svcadm disable -s svc:/network/puppetagent:default')
  elsif agent['platform'].include?('debian') or agent['platform'].include?('ubuntu')
    on(agent, '/etc/init.d/pe-puppet-agent stop')
  elsif agent['platform'].include?('windows')
    on(agent, 'net stop puppet', :acceptable_exit_codes => [0,2])
  else
    on(agent, '/etc/init.d/pe-puppet stop')
  end
end

step 'Sleeping'
sleep 20

step 'Running puppet agent --test on each agent'
on agents, puppet_agent('--test'), :acceptable_exit_codes => [0,2]
