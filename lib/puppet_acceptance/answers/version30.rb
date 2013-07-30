module PuppetAcceptance
  module Answers
    module Version30

      def self.host_answers(host, master_certname, master, database, dashboard)
        # Windows hosts don't have normal answers...
        return nil if host['platform'] =~ /windows/

        # Everything's an agent
        agent_a = {
          :q_install => 'y',
          :q_puppetagent_install => 'y',
          :q_puppet_cloud_install => 'y',
          :q_verify_packages => ENV['q_verify_packages'] || 'y',
          :q_puppet_symlinks_install => 'y',
          :q_vendor_packages_install => 'y',
          :q_puppetagent_certname => host,
          :q_puppetagent_server => master,

          # Disable database, console, and master by default
          # This will be overridden by other blocks being merged in.
          :q_puppetmaster_install => 'n',
          :q_all_in_one_install => 'n',
          :q_puppet_enterpriseconsole_install => 'n',
          :q_puppetdb_install => 'n',
          :q_database_install => 'n',
        }

        # master/database answers
        master_database_a = {
          :q_puppetmaster_certname => master_certname
        }

        # Master/dashboard answers
        master_console_a = {
          :q_puppetdb_hostname => database,
          :q_puppetdb_port => 8081
        }

        # Master only answers
        master_a = {
          :q_puppetmaster_install => 'y',
          :q_puppetmaster_dnsaltnames => master_certname+",puppet",
          :q_puppetmaster_enterpriseconsole_hostname => dashboard,
          :q_puppetmaster_enterpriseconsole_port => 443,
        }

        if master['ip']
          master_a[:q_puppetmaster_dnsaltnames]+=","+master['ip']
        end

        # Common answers for console and database
        dashboard_password = "'#{ENV['q_puppet_enterpriseconsole_auth_password'] || '~!@#$%^*-/ aZ'}'"
        puppetdb_password = "'#{ENV['q_puppetdb_password'] || '~!@#$%^*-/ aZ'}'"

        console_database_a = {
          :q_puppetdb_database_name => 'pe-puppetdb',
          :q_puppetdb_database_user => 'mYpdBu3r',
          :q_puppetdb_database_password => puppetdb_password,
          :q_puppet_enterpriseconsole_auth_database_name => 'console_auth',
          :q_puppet_enterpriseconsole_auth_database_user => 'mYu7hu3r',
          :q_puppet_enterpriseconsole_auth_database_password => dashboard_password,
          :q_puppet_enterpriseconsole_database_name => 'console',
          :q_puppet_enterpriseconsole_database_user => 'mYc0nS03u3r',
          :q_puppet_enterpriseconsole_database_password => dashboard_password,

          :q_database_host => database,
          :q_database_port => 5432
        }

        # Console only answers
        dashboard_user = "'#{ENV['q_puppet_enterpriseconsole_auth_user_email'] || 'admin@example.com'}'"

        smtp_host = "'#{ENV['q_puppet_enterpriseconsole_smtp_host'] || dashboard}'"
        smtp_port = "'#{ENV['q_puppet_enterpriseconsole_smtp_port'] || 25}'"
        smtp_username = ENV['q_puppet_enterpriseconsole_smtp_username']
        smtp_password = ENV['q_puppet_enterpriseconsole_smtp_password']
        smtp_use_tls = "'#{ENV['q_puppet_enterpriseconsole_smtp_use_tls'] || 'n'}'"

        console_a = {
          :q_puppet_enterpriseconsole_install => 'y',
          :q_puppet_enterpriseconsole_inventory_hostname => host,
          :q_puppet_enterpriseconsole_inventory_certname => host,
          :q_puppet_enterpriseconsole_inventory_dnsaltnames => dashboard,
          :q_puppet_enterpriseconsole_inventory_port => 8140,
          :q_puppet_enterpriseconsole_master_hostname => master,

          :q_puppet_enterpriseconsole_auth_user_email => dashboard_user,
          :q_puppet_enterpriseconsole_auth_password => dashboard_password,

          :q_puppet_enterpriseconsole_httpd_port => 443,

          :q_puppet_enterpriseconsole_smtp_host => smtp_host,
          :q_puppet_enterpriseconsole_smtp_use_tls => smtp_use_tls,
          :q_puppet_enterpriseconsole_smtp_port => smtp_port,

          :q_pe_database => 'y',
        }

        if smtp_password and smtp_username
          console_a.merge!({
                             :q_puppet_enterpriseconsole_smtp_password => "'#{smtp_password}'",
                             :q_puppet_enterpriseconsole_smtp_username => "'#{smtp_username}'",
                             :q_puppet_enterpriseconsole_smtp_user_auth => 'y'
                           })
        end

        # Database only answers
        database_a = {
          :q_puppetdb_install => 'y',
          :q_database_install => 'y',
          :q_database_root_password => "'=ZYdjiP3jCwV5eo9s1MBd'",
          :q_database_root_user => 'pe-postgres',
        }

        # Special answers for special hosts
        aix_a = {
          :q_run_updtvpkg => 'y',
        }

        answers = agent_a.dup
        if host == master
          answers.merge! master_a
          answers.merge! master_console_a
          answers.merge! master_database_a
        end

        if host == dashboard
          answers.merge! console_a
          answers.merge! master_console_a
          answers.merge! console_database_a
        end

        if host == database
          answers.merge! database_a
          answers.merge! console_database_a
          answers.merge! master_database_a
        end

        if host == master and host == database and host == dashboard
          answers[:q_all_in_one_install] = 'y'
        end

        if host['platform'].include? 'aix'
          answers.merge! aix_a
        end

        return answers
      end

      def self.answers(hosts, master_certname)
        the_answers = {}
        database = only_host_with_role(hosts, 'database')
        dashboard = only_host_with_role(hosts, 'dashboard')
        master = only_host_with_role(hosts, 'master')
        hosts.each do |h|
          the_answers[h.name] = host_answers(h, master_certname, master, database, dashboard)
        end
        return the_answers
      end

    end
  end
end
