Describe "Talos Spec Helper Functions"
  Include "spec/support/modifiers/yq.sh"
  Include "terraform/talos/spec/spec_helper.sh"

  Describe "is_present function"
    Parameters
      "null" false
      "" false
      "[]" false
      "{}" false
      "valid-value" true
      '["item"]' true
    End

    Example "should validate $1 as $2"
      When call echo "$1"
      if [ "$2" = "true" ]; then
        The output should satisfy is_present
      else
        The output should not satisfy is_present
      fi
    End
  End

  Describe "is_ipv6_cidr function"
    Parameters
      "10.244.0.0/16" false
      "192.168.1.0/24" false
      "2001:db8::/32" true
      "fe80::/64" true
      "::1/128" true
    End

    Example "should validate $1 as IPv6: $2"
      When call echo -n "$1"
      if [ "$2" = "true" ]; then
        The output should satisfy is_ipv6_cidr
      else
        The output should not satisfy is_ipv6_cidr
      fi
    End
  End

  Describe "is_semver function"
    Parameters
      "v1.2.3" true
      "v10.20.30" true
      "1.2.3" false
      "v1.2" false
      "v1.2.3.4" false
      "invalid" false
    End

    Example "should validate $1 as semver: $2"
      When call echo "$1"
      if [ "$2" = "true" ]; then
        The output should satisfy is_semver
      else
        The output should not satisfy is_semver
      fi
    End
  End
End
