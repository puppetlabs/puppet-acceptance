test_name "Basic Agent Functionality" do

  agents.each do |agent|
    step "Stopping puppet agent on #{agent}"

    # These Solaris and Windows values are from PE,
    # may need revision for FOSS
    if agent['platform'].include?('solaris')
      on agent, '/usr/sbin/svcadm disable -s svc:/network/puppetagent:default'
    elsif agent['platform'].include?('windows')
      on agent, 'net stop puppet', :acceptable_exit_codes => [0,2]
    else
      on agent, 'service puppet stop'
    end
  end

  step 'Sleeping'
  sleep 20

  step 'Running puppet agent --test on each agent'
  on master, puppet( 'master' )
  on agents, puppet_agent('--test'), :acceptable_exit_codes => [0,2]
end
