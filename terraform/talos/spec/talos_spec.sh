Describe "talos version checking"

  Include "spec/support/modifiers/yq.sh"
  Include "terraform/talos/spec/spec_helper.sh"
  Include "terraform/talos/modules/talos-version/scripts/lib.sh"

  Describe "talos_version"
    It "returns valid JSON with version"
      When call talos_version
      The status should be success
      The output as yq '.version' should satisfy is_semver
    End
  End

  Describe "k8s_version"
    It "returns valid JSON with version"
      When call k8s_version
      The status should be success
      The output as yq '.version' should satisfy is_semver
    End
  End

  Describe "compare_versions"
    It "returns equal for same versions"
      When call compare_versions "v1.2.3" "v1.2.3"
      The status should be success
      The output as yq '.comparison' should equal "equal"
    End

    It "returns upgrade for newer desired version"
      When call compare_versions "v1.2.3" "v1.3.0"
      The status should be success
      The output as yq '.comparison' should equal "upgrade"
    End

    It "returns downgrade for older desired version"
      When call compare_versions "v1.3.0" "v1.2.3"
      The status should be success
      The output as yq '.comparison' should equal "downgrade"
    End

    It "fails when current version is empty"
      When call compare_versions "" "v1.2.3"
      The status should be failure
      The stderr should include "Both current and desired versions must be provided"
    End

    It "fails when desired version is empty"
      When call compare_versions "v1.2.3" ""
      The status should be failure
      The stderr should include "Both current and desired versions must be provided"
    End
  End

  Describe "get_last_wipe_state"
    It "returns default JSON when file doesn't exist"
      When call get_last_wipe_state "/nonexistent-file.json"
      The status should be success
      The output as yq '.last_wipe_at' should equal "1970-01-01T00:00:00Z"
    End

    It "fails when path is not provided"
      When call get_last_wipe_state
      The status should be failure
      The stderr should include "Path must be provided"
    End

    xIt "fails when bucket env var is not set"
      # It doesn't seem possible to unset an env var
      unset TF_VAR_terraform_statefile_bucket
      When call get_last_wipe_state "/test-path.json"
      The status should be failure
      The stderr should include "TF_VAR_terraform_statefile_bucket not set"
    End

    Describe "S3 integration"
      upload_test_data() {
        # Use --s3-no-check-bucket to prevent rclone from trying to create the bucket
        # The bucket already exists and we just want to upload files to it
        echo -n '{"last_wipe_at": "2026-01-25T17:55:00Z"}' | _rclone rcat /test-wipe-state.json --s3-no-check-bucket
      }
      
      cleanup_test_data() {
        _rclone delete /test-wipe-state.json
      }

      Before "upload_test_data"
      After "cleanup_test_data"

      It "fetches existing JSON from S3"
        When call get_last_wipe_state "/test-wipe-state.json"
        The status should be success
        The output as yq '.last_wipe_at' should equal "2026-01-25T17:55:00Z"
      End
    End
  End
End
