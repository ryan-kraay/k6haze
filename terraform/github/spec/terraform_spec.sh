Describe "Terraform"
  It "trims single-quoted values"
    # WARNING:  "Skip if" will only run a _single_ command.  Using && to chain them together will
    #  result in errors.  However, you can create a function call and run as many commands as you'd
    #  like.
    #  Meanwhile, we'll use 'test's build-in '-a' argument for a logic AND
    Skip if "RUNNER_OS and SPEC_QUOTE are not set" test -z "${RUNNER_OS:-}" -a -z "${SPEC_QUOTE:-}"
    When run echo "${SPEC_QUOTE:-SPEC_QUOTE NOT DEFINED}"
    The output should eq "{\"hello\": \"world\"}"
  End
End
