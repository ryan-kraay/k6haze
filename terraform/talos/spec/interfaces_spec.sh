Describe "Talos Network Bridge Interfaces"
  Include "spec/support/modifiers/jq.sh"

  # Wrapper for talosctl that suppresses non-critical warnings while preserving other stderr
  talosctl() {
    command talosctl "$@" 2> >(grep -v "server version.*is older than client version" >&2)
  }

  # Check if value is present (not null, empty string, empty list, empty map)
  is_present() {
    [ "${is_present:-}" != "null" ] && [ "${is_present:-}" != "" ] && [ "${is_present:-}" != "[]" ] && [ "${is_present:-}" != "{}" ]
  }

  # Get interface data by interface name
  get_interface() {
    talosctl get links -o json | jq -rs "(.[] | select(.metadata.id == \"$1\")) // \"null\""
  }

  # Get all address data by interface name or an empty array
  get_addresses() {
    talosctl get addresses -o json | jq -rs "[.[] | select(.spec.linkName == \"$1\")]"
  }

  Describe "Helper function validation"
    Describe "get_interface function"
      It "should return null for non-existent interface"
        When call get_interface "non-existent"
        The output should equal "null"
        The output as jq '.nonexistent' should equal "null"
      End

      It "should return valid JSON for existing interface"
        When call get_interface "ens3"
        The output as jq '.metadata.id' should equal "ens3"
      End
    End

    Describe "get_addresses function"
      It "should return empty array for non-existent address"
        When call get_addresses "dummy1"
        The output should equal "[]"
        The output as jq '[.[] | select(.spec.family == "inet6")] | length' should equal "0"
        The output as jq '.[] | select(.spec.family == "inet6") | .spec.address' should not satisfy is_present
      End

      It "should return valid JSON for existing address"
        When call get_addresses "ens3"
        The output as jq '.[] | select(.spec.family == "inet4") | .spec.linkName' should equal "ens3"
        The output as jq '.[] | select(.spec.family == "inet4") | .metadata.id' should satisfy is_present
      End
    End

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
  End

  Describe "Physical interface ens3"
    It "should exist and be up"
      When call get_interface "ens3"
      The output as jq '.metadata.id' should equal "ens3"
      The output as jq '.spec.operationalState' should equal "up"
    End

    It "should not have IP addresses assigned (manual mode)"
      When call get_addresses "ens3"
      The output as jq 'length' should equal "0"
    End
  End

  Describe "Bridge interface br0"
    It "should exist as a bridge"
      When call get_interface "br0"
      The output as jq '.spec.kind' should equal "bridge"
      The output as jq '.spec.operationalState' should equal "up"
    End

    It "should not have IP addresses assigned"
      When call get_addresses "br0"
      The output as jq 'length' should equal "0"
    End
  End

  Describe "IPv4 interface wan4"
    It "should exist and be up"
      When call get_interface "wan4"
      The output as jq '.metadata.id' should equal "wan4"
      The output as jq '.spec.operationalState' should equal "up"
    End

    It "should be attached to bridge br0"
      When call get_interface "wan4"
      The output as jq '.spec.masterIndex' should be present
      The output as jq '.spec.slaveKind' should equal "bridge"
    End

    It "should have IPv4 address configured"
      When call get_addresses "wan4"
      The output as jq '[.[] | select(.spec.family == "inet4")] | length' should equal "1"
      The output as jq '.[] | select(.spec.family == "inet4") | .spec.address' should satisfy is_present
    End

    xIt "should have IPv4 default route"
      When call talosctl get routes -o json
      The output as jq '[.[] | select(.spec.destination == "0.0.0.0/0")] | length' should be greater than "0"
    End
  End

  Describe "IPv6 interface wan6"
    It "should exist and be up"
      When call get_interface "wan6"
      The output as jq '.metadata.id' should equal "wan6"
      The output as jq '.spec.operationalState' should equal "up"
    End

    It "should be attached to bridge br0"
      When call get_interface "wan6"
      The output as jq '.spec.masterIndex' should be present
      The output as jq '.spec.slaveKind' should equal "bridge"
    End

    It "should have IPv6 address configured"
      When call get_addresses "wan6"
      The output as jq '[.[] | select(.spec.family == "inet6")] | length' should equal "1"
      The output as jq '.[] | select(.spec.family == "inet6") | .spec.address' should satisfy is_present
    End

    xIt "should have IPv6 default route"
      When call talosctl get routes -o json
      The output as jq '[.[] | select(.spec.destination == "::/0")] | length' should be greater than "0"
    End
  End

  Describe "Network topology validation"
    It "should have ens3 as bridge member"
      When call get_interface "ens3"
      The output as jq '.spec.masterIndex' should be present
      The output as jq '.spec.slaveKind' should equal "bridge"
    End
  End
End
