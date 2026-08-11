Describe "read_secrets.sh"
  script="devbox-plugins/common/bin/read_secrets.sh"
  fixtures="spec/fixtures/read_secrets"

  # These variables are not accessible from within the Mock, thus
  #  are duplicated.
  env_key1="FOO"   env_val1="bar"
  env_key2="BAZ"   env_val2="qux=with=equals"
  raw_key="MY_RAW_SECRET"  raw_val="raw value"

  Mock sops
    # The contents of Mock get dumped into a shell script, thus
    #  the variables are not accessible from outside the Mock.
    env_key1="FOO"   env_val1="bar"
    env_key2="BAZ"   env_val2="qux=with=equals"
    raw_key="MY_RAW_SECRET"  raw_val="raw value"
    case "$2" in
      *.sops.env) printf "${env_key1}=${env_val1}\n# a comment\n${env_key2}=${env_val2}\n" ;;
      *.sops.raw) printf "${raw_val}" ;;
    esac
  End

  Describe "local mode (no GITHUB_ENV arg)"
    It "emits sourceable key=value for env secrets"
      When run script "${script}" "${fixtures}" ""
      The line 1 of output should equal "${env_key1}=${env_val1}"
      The line 2 of output should equal "${env_key2}=${env_val2}"
    End

    It "skips comments"
      When run script "${script}" "${fixtures}"
      The output should not include "# a comment"
    End

    It "emits KEY=value for raw secrets"
      When run script "${script}" "${fixtures}"
      The output should include "${raw_key}=${raw_val}"
    End
  End

  Describe "GHA mode (GITHUB_ENV arg provided)"
    setup() { tmpfile=$(mktemp); }
    cleanup() { rm -f "${tmpfile}"; }
    BeforeEach setup
    AfterEach  cleanup

    It "masks each secret value"
      When run script "${script}" "${fixtures}" "${tmpfile}"
      The line 1 of output should equal "::add-mask::${env_val1}"
      The line 2 of output should equal "::add-mask::${env_val2}"
      The line 3 of output should equal "::add-mask::${raw_val}"
    End

    It "does not emit key=value to stdout"
      When run script "${script}" "${fixtures}" "${tmpfile}"
      The output should not include "${env_key1}=${env_val1}"
    End

    It "writes secrets to GITHUB_ENV file and masks values on stdout"
      When run script "${script}" "${fixtures}" "${tmpfile}"
      The line 1 of output should equal "::add-mask::${env_val1}"
      The line 1 of contents of file "${tmpfile}" should equal "${env_key1}=${env_val1}"

      The line 2 of output should equal "::add-mask::${env_val2}"
      The line 2 of contents of file "${tmpfile}" should equal "${env_key2}=${env_val2}"

      The line 3 of output should equal "::add-mask::${raw_val}"
      The line 3 of contents of file "${tmpfile}" should equal "${raw_key}=${raw_val}"
    End
  End

  Describe "error handling"
    It "fails when no secrets_dir is provided"
      When run script "${script}"
      The status should be failure
      The stderr should be present
    End

    It "fails when secrets_dir does not exist"
      When run script "${script}" /nonexistent/path
      The status should be failure
      The stderr should include "directory not found: /nonexistent/path"
    End
  End
End
