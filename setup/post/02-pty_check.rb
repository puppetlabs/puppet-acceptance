# Check if we can allocate a pseudo TTY

test_name "Check machines for allocation of PTY"

step "check for allocate pty"

hosts.each do |host|
  on(host, "tty", :request_pty => 1) do
    assert_equal( 0, exit_code, "allocate pty failed") 
  end
end

step "check for not a tty"

hosts.each do |host|
  on(host, "tty", :request_pty => 0, :acceptable_exit_codes => [1] ) do
    assert_match( "not a tty" , stdout, "lack of PTY test failed")
  end
end
