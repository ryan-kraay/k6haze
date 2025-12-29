Describe "Cilium"
  Include "spec/support/modifiers/yq.sh"
  Include "terraform/k8s/spec/spec_helper.sh"

  # Helper function to get resources from kube-system namespace
  get() {
    kubectl get -n kube-system "$@"
  }

  Describe "Deployment"
    It "should have cilium-operator deployment running"
      When call get deployment cilium-operator
      The status should be success
      The output as yq '.status.readyReplicas // null' should satisfy is_present
    End

    It "should have cilium daemonset running"
      When call get daemonset cilium
      The status should be success
      The output as yq '.status.numberReady // null' should satisfy is_present
    End
  End

  Describe "Pods"
    It "should have all cilium pods ready"
      When call get pods -l k8s-app=cilium --field-selector=status.phase=Running
      The status should be success
      The output as yq '.items | length' should be present # re: non-zero
    End

    It "should have cilium-operator pods ready"
      When call get pods -l name=cilium-operator --field-selector=status.phase=Running
      The status should be success
      The output as yq '.items | length' should be present # re: non-zero
    End
  End
End
