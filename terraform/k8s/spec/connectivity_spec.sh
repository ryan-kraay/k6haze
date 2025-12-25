fDescribe "Connectivity Test"
  Include "spec/support/modifiers/yq.sh"
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

  client_curl() {
    client_exec curl -6 -s -w '{"status":%{http_code},"time":%{time_total},"size":%{size_download}}' -o /dev/null "$@"
  }

  get_server_pod_ip() {
    command kubectl get pod -n "${TEST_NS}" -l app=server -o jsonpath='{.items[0].status.podIP}'
  }

  It "should allow client to connect directly to server pod"
    server_pod=$(command kubectl get pod -n "${TEST_NS}" -l app=server -o jsonpath='{.items[0].status.podIP}')
    When call client_curl "http://[${server_pod}]:8080"
    The status should be success
    The output as yq '.status' should equal '200'
  End

  It "should allow client to connect to gateway external IP"
    gateway_external_ip=$(command kubectl get svc -n "${TEST_NS}" cilium-gateway-internal-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    When call client_curl "http://[${gateway_external_ip}]:8080"
    The status should be success
    The output as yq '.status' should equal '200'
  End

  Describe "HTTP connectivity"
    Parameters
      "http://server:80"
      "http://cilium-gateway-internal-gateway:8080"
      "https://www.google.com/robots.txt"
    End

    It "should allow client to connect to ${1}"
      When call client_curl "${1}"
      The status should be success
      The output as yq '.status' should equal '200'
    End
  End
End
