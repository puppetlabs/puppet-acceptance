test_name 'Sign Requested Agent Certs' do

  with_master_running_on master do
    agents.each do |agent|
      on agent, puppet( 'agent -t' ), :acceptable_exit_codes => [0,1]

      signed = false
      wait = 1

      (0..10).each do |i|
        step "Checking if cert issued for #{agent} (#{i})" do
          signed_agent_regexp = /^#{Regexp.escape("+ \"#{agent.name}")}/

          on master,
             puppet("cert --sign --all"),
             :acceptable_exit_codes => [0,24]

          signing_result = on( master, puppet( 'cert list --all' ) )

          signed = true if signing_result.stdout =~ signed_agent_regexp

          unless signed
            logger.debug( signing_result.stdout )
            logger.debug( 'did not match:' )
            logger.debug( signed_agent_regexp )
          end
        end

        break if signed

        fail_test("Failed to sign cert for #{agent}") if i == 10

        step "Wait for agent #{agent}: #{i}" do
          sleep wait
          wait += i
        end
      end
    end
  end
end

