fDescribe "Connectivity Test"
  Include "terraform/k8s/spec/spec_helper.sh"

  TEST_NS="connectivity-test"
  TEST_RELEASE="test-env"

  BeforeAll "setup_test_environment"
  AfterAll "cleanup_test_environment"

  setup_test_environment() {
    helm upgrade --install "$TEST_RELEASE" terraform/k8s/spec/charts/test-env \
      -n "$TEST_NS" --create-namespace --wait --timeout=300s
  }

  cleanup_test_environment() {
    if [ -z "${DEBUG_PODS:-}" ]; then
      helm uninstall "$TEST_RELEASE" -n "$TEST_NS" --wait --timeout=60s
      command kubectl delete namespace "$TEST_NS" --ignore-not-found=true --timeout=60s
    else
      echo "DEBUG_PODS enabled -- skipping teardown"
    fi
  }

  client_exec() {
    command kubectl exec -n "${TEST_NS}" deployment/client -- timeout 1s "${@}"
  }

  It "should allow client to connect to server"
    When call client_exec wget -qO- http://server:80
    The status should be success
    The output should include "Directory listing"
  End
End
