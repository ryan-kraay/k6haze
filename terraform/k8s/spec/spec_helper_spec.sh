Describe "spec_helper"
  Include "spec/support/modifiers/yq.sh"
  Include "terraform/k8s/spec/spec_helper.sh"

  Describe "kubectl wrapper"
    fIt "should return valid JSON output"
      When run kubectl version --client
      The status should be success
      The output as yq '.clientVersion.gitVersion // null' should satisfy is_present
    End
  End
End
