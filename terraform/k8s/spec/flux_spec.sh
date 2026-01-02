Describe "Flux"
  Include "spec/support/modifiers/yq.sh"
  Include "terraform/k8s/spec/spec_helper.sh"

  # Helper function to get resources from flux-system namespace
  get() {
    kubectl get -n flux-system "$@"
  }

  Describe "Deployment"
    Parameters
      "helm-controller"
      "kustomize-controller"
      "notification-controller"
      "source-controller"
    End

    It "should have ${1} running"
      When call get deployment "${1}"
      The status should be success
      The output as yq '.status.readyReplicas // null' should satisfy is_present
    End

  End


  Describe "GitRepository"
    It "should be active"
      get_gitrepository() {
        # TODO HardCoding "homelab" is kinda lame, maybe I can add a label instead
        subject=$(get gitrepository homelab | yq '[.status.conditions[] | select(.type == "Ready")][0] // null')
        %preserve subject
      }
      When run get_gitrepository
      The status should be success
      The variable subject should satisfy is_present
      The variable subject as yq '.status' should equal "True"
    End
  End
End
