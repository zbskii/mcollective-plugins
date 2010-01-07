module MCollective
    module Agent
        class Puppetd<RPC::Agent
            def startup_hook
                meta[:license] = "Apache License 2.0"
                meta[:author] = "R.I.Pienaar"
                meta[:version] = "1.1"
                meta[:url] = "http://mcollective-plugins.googlecode.com/"

                @timeout = 10

                @splaytime = @config.pluginconf["puppetd.splaytime"].to_i || 0
                @lockfile = @config.pluginconf["puppetd.lockfile"] || "/var/lib/puppet/state/puppetdlock"
                @puppetd = @config.pluginconf["puppetd.puppetd"] || "/usr/sbin/puppetd"
            end

            def enable_action
                enable
            end

            def disable_action
                disable
            end

            def runonce_action
                runonce
            end

            def status_action
                status
            end

            def help
                <<-EOH
                Simple RPC Puppetd Agent
                ========================
    
                Agent to enable, disable and run the puppet agent
    
                ACTIONS:
                    enable, disable, status, runonce

                INPUT:
                    none

                OUTPUT:
                    :output     A string showing some human parsable status
                    :enabled    for the status action, 1 if the daemon is enabled, 0 otherwise

                CONFIGURATION 
                -------------

                puppetd.splaytime - How long to splay for, no splay by default
                puppetd.lockfile  - Where to find the lock file defaults to 
                                    /var/lib/puppet/state/puppetdlock
                puppetd.puppetd   - Where to find the puppetd, defaults to 
                                    /usr/sbin/puppetd
                EOH
            end

            private
            def status
                if File.exists?(@lockfile)
                    if File::Stat.new(@lockfile).zero?
                        reply[:output] = "Disabled, not running"
                        reply[:enabled] = 0
                    else
                        reply[:output] = "Enabled, running"
                        reply[:enabled] = 1
                    end
                end
            end

            def runonce
                if File.exists?(@lockfile)
                    reply.fail "Lock file exists"
                else
                    if @splaytime > 0
                        reply[:output] = %x[#{@puppetd} --onetime --splaylimit #{@splaytime} --splay]
                    else
                        reply[:output] = %x[#{@puppetd} --onetime]
                    end
                end
            end

            def enable
                if File.exists?(@lockfile)
                    stat = File::Stat.new(@lockfile)

                    if stat.zero?
                        File.unlink(@lockfile)
                        reply[:output] = "Lock removed"
                    else
                        reply[:output] = "Currently runing"
                    end
                else
                    reply.fail "Already unlocked"
                end
            end

            def disable
                if File.exists?(@lockfile)
                    stat = File::Stat.new(@lockfile)

                    stat.zero? ? reply.fail("Already disabled") : reply.fail("Currently running")
                else
                    reply[:output] = %x[#{@puppetd} --disable]

                    reply[:output] = "Lock created" if reply[:output] == ""
                end
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby
