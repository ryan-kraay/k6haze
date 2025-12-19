Describe "Talos Cluster"
  Include "spec/support/modifiers/yq.sh"

  # Wrapper for talosctl that suppresses non-critical warnings while preserving other stderr
  talosctl() {
    command talosctl "$@" 2> >(grep -v "server version.*is older than client version" >&2)
  }

  # Check if value is present (not null, empty string, empty list, empty map)
  is_present() {
    [ "${is_present:-}" != "null" ] && [ "${is_present:-}" != "" ] && [ "${is_present:-}" != "[]" ] && [ "${is_present:-}" != "{}" ]
  }

  # Check if CIDR is IPv6
  is_ipv6_cidr() {
    echo "$1" | grep -q ':'
  }

  Describe "Network"
    fIt "should have podSubnets configured as IPv6"
      func() { 
        subject=$(talosctl get machineconfig v1alpha1 -o json)
        %preserve subject
      }

      When run func
      The status should be success
      subnet_count=$(echo -n "$subject" | yq '.spec | fromyaml | .cluster.network.podSubnets | length')
      The variable subnet_count should be present #re: non-zero
      for i in $(seq 0 $((subnet_count - 1))); do
        The variable subject as yq ".spec | fromyaml | .cluster.network.podSubnets[$i]" should satisfy is_present
        The variable subject as yq ".spec | fromyaml | .cluster.network.podSubnets[$i]" should satisfy is_ipv6_cidr
      done
    End

    It "should have serviceSubnets configured as IPv6"
      When call talosctl get machineconfig v1alpha1 -o json
      The status should be success
      The output as yq '.spec | fromyaml | .cluster.network.serviceSubnets[0]' should satisfy is_present
      The output as yq '.spec | fromyaml | .cluster.network.serviceSubnets[0]' should satisfy is_ipv6_cidr
    End
  End
End
