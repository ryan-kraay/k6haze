Describe "determine"

  Include "$SHELLSPEC_HELPERDIR/../../../.github/scripts/determine.sh"

  Describe "with no input"
    Data
    End
    It "returns all false"
      When call determine_changes
      The output as jq ".changed_github" should equal "false"
      The output as jq ".changed_github_spec" should equal "false"
      The output as jq ".changed_talos" should equal "false"
      The output as jq ".changed_talos_spec" should equal "false"
      The output as jq ".changed_k8s" should equal "false"
      The output as jq ".changed_k8s_spec" should equal "false"
    End
  End

  Describe "with project changes"
    Parameters
      github
      talos
      k8s
    End

    Example "on ${1} terraform"
      Data:expand
        #|terraform/${1}/main.tf
      End
      When call determine_changes
      The output as jq ".changed_${1}" should equal "true"
      # Changes to our terraform code will trigger the spec to rerun
      The output as jq ".changed_${1}_spec" should equal "true"
    End

    Example "on ${1} spec"
      Data:expand  # expand will cause ${1} to be expanded
        #|terraform/${1}/spec/something_spec.sh
      End
      When call determine_changes
      The output as jq ".changed_${1}_spec" should equal "true"
      # Changes to the spec will _not_ trigger terraform to rerun
      The output as jq ".changed_${1}" should equal "false"
    End
  End

  Describe "when github changes"
    Data
      #|terraform/github/main.tf
    End
    It "sets flags for talos and k8s"
      When call determine_changes
      The output as jq ".changed_github" should equal "true"
      The output as jq ".changed_github_spec" should equal "true"
      The output as jq ".changed_talos" should equal "true"
      The output as jq ".changed_talos_spec" should equal "true"
      The output as jq ".changed_k8s" should equal "true"
      The output as jq ".changed_k8s_spec" should equal "true"
    End
  End

  Describe "when talos changes"
    Data
      #|terraform/talos/main.tf
    End
    It "sets flags for k8s"
      When call determine_changes
      The output as jq ".changed_github" should equal "false"
      The output as jq ".changed_github_spec" should equal "false"
      The output as jq ".changed_talos" should equal "true"
      The output as jq ".changed_talos_spec" should equal "true"
      The output as jq ".changed_k8s" should equal "true"
      The output as jq ".changed_k8s_spec" should equal "true"
    End
  End

  Describe "when k8s changes"
    Data
      #|terraform/k8s/main.tf
    End
    It "sets no additional flags"
      When call determine_changes
      The output as jq ".changed_github" should equal "false"
      The output as jq ".changed_github_spec" should equal "false"
      The output as jq ".changed_talos" should equal "false"
      The output as jq ".changed_talos_spec" should equal "false"
      The output as jq ".changed_k8s" should equal "true"
      The output as jq ".changed_k8s_spec" should equal "true"
    End
  End

  Describe "when docs change"
    Data
      #|README.md
      #|foo/bar/.gitignore
      #|.gitignore
    End
    It "sets no changes"
      When call determine_changes
      The output as jq ".changed_github" should equal "false"
      The output as jq ".changed_github_spec" should equal "false"
      The output as jq ".changed_talos" should equal "false"
      The output as jq ".changed_talos_spec" should equal "false"
      The output as jq ".changed_k8s" should equal "false"
      The output as jq ".changed_k8s_spec" should equal "false"
    End
  End

  Describe "when an unknown files changes"
    Data
      #|devbox.json
    End
    It "sets all changes"
      When call determine_changes
      The output as jq ".changed_github" should equal "true"
      The output as jq ".changed_github_spec" should equal "true"
      The output as jq ".changed_talos" should equal "true"
      The output as jq ".changed_talos_spec" should equal "true"
      The output as jq ".changed_k8s" should equal "true"
      The output as jq ".changed_k8s_spec" should equal "true"
    End
  End

End
