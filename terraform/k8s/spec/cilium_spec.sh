Describe "Cilium"
  Include "spec/support/modifiers/yq.sh"
  Include "terraform/k8s/spec/spec_helper.sh"

  Describe "Deployment"
    It "should have cilium-operator deployment running"
      get_cilium_operator() {
        subject=$(kubectl get deployment cilium-operator -n kube-system | yq '.status.readyReplicas // null')
        %preserve subject
      }

      When run get_cilium_operator
      The status should be success
      The variable subject should satisfy is_present
    End

    It "should have cilium daemonset running"
      get_cilium_daemonset() {
        subject=$(kubectl get daemonset cilium -n kube-system | yq '.status.numberReady // null')
        %preserve subject
      }

      When run get_cilium_daemonset
      The status should be success
      The variable subject should satisfy is_present
    End
  End

  Describe "Pods"
    It "should have all cilium pods ready"
      get_cilium_pods() {
        subject=$(kubectl get pods -n kube-system -l k8s-app=cilium --field-selector=status.phase=Running | yq '.items | length')
        %preserve subject
      }

      When run get_cilium_pods
      The status should be success
      The variable subject should satisfy is_present
    End

    It "should have cilium-operator pods ready"
      get_operator_pods() {
        subject=$(kubectl get pods -n kube-system -l name=cilium-operator --field-selector=status.phase=Running | yq '.items | length')
        %preserve subject
      }

      When run get_operator_pods
      The status should be success
      The variable subject should satisfy is_present
    End
  End
End
