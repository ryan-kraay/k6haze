Describe "Talos Cluster"
  Include "spec/support/modifiers/yq.sh"
  Include "terraform/talos/spec/spec_helper.sh"

  # Get machine configuration as parsed YAML
  get_machineconfig() {
    talosctl get machineconfig v1alpha1 -o json | yq -o json '.spec | fromyaml'
  }

  Describe "Network"
    It "should have podSubnets configured as IPv6"
      get_pod_subnets() {
        subject=$(get_machineconfig | yq '.cluster.network.podSubnets // null')
        %preserve subject
      }

      When run get_pod_subnets
      The status should be success
      The variable subject should satisfy is_present

      subnet_count=$(echo -n "$subject" | yq 'length')
      The variable subnet_count should be present #re: non-zero
      for i in $(seq 0 $((subnet_count - 1))); do
        The variable subject as yq ".[$i]" should satisfy is_present
        The variable subject as yq ".[$i]" should satisfy is_ipv6_cidr
      done
    End

    It "should have serviceSubnets configured as IPv6"
      get_service_subnets() {
        subject=$(get_machineconfig | yq '.cluster.network.serviceSubnets // null')
        %preserve subject
      }

      When run get_service_subnets
      The status should be success
      The variable subject should satisfy is_present

      subnet_count=$(echo -n "$subject" | yq 'length')
      The variable subnet_count should be present #re: non-zero
      for i in $(seq 0 $((subnet_count - 1))); do
        The variable subject as yq ".[$i]" should satisfy is_present
        The variable subject as yq ".[$i]" should satisfy is_ipv6_cidr
      done
    End
  End

  Describe "Services"
    # can be obtained by running: `talosctl service`
    #  TODO: make this dynamic (and skip dashboard)
    Parameters
      apid
      auditd
      containerd
      cri
      etcd
      kubelet
      machined
      syslogd
      trustd
      udevd
    End

    Example "$1 should be running with OK health"
      get_service_status() {
        # Replace NODE line with blank line to prevent hostname leakage while preserving line numbers
        talosctl service "$1" status | sed -e 's/^NODE[[:space:]]\+.*$//'
      }

      When run get_service_status $1
      The status should be success
      # Relying on line numbers is brittle, but there is no json output
      The line 1 should equal ""
      The line 3 should match pattern "STATE*Running"
      The line 4 should match pattern "HEALTH*OK"
    End
  End
End
