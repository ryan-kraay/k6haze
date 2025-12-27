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
    local client_name="$1"
    shift
    command kubectl exec -n "${TEST_NS}" deployment/"${client_name}" -- timeout 1s "${@}"
  }

  client_curl() {
    local client_name="$1"
    shift
    client_exec "${client_name}" curl -6 -s -w '{"status":%{http_code},"time":%{time_total},"size":%{size_download}}' -o /dev/null "$@"
  }

  get_server_pod_url() {
    server_pod=$(command kubectl get pod -n "${TEST_NS}" -l app=server -o jsonpath='{.items[0].status.podIP}')
    echo "http://[${server_pod}]:8080"
  }

  get_gateway_external_url() {
    gateway_ip=$(command kubectl get svc -n "${TEST_NS}" cilium-gateway-internal-gateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    echo "http://[${gateway_ip}]:8080"
  }

  Describe "HTTP connectivity"
    Parameters:dynamic
      # pod -> pod
      desc="pod -> pod"
      # this is a stub, because shellspec cannot reliably execute a function call from here.
      url="get_server_pod_url"
      %data "$desc" "good-client" "$url" true
      %data "$desc" "bad-client" "$url" false

      # pod -> service
      desc="pod -> service"
      url="http://server:80"
      %data "$desc" "good-client" "$url" true
      %data "$desc" "bad-client" "$url" false

      # pod -> gateway-api(internal)
      desc="pod -> gateway-api(internal)"
      url="http://cilium-gateway-internal-gateway:8080"
      %data "$desc" "good-client" "$url" true
      %data "$desc" "bad-client" "$url" false

      # pod -> gateway-api(external)
      desc="pod -> gateway-api(external)"
      url="get_gateway_external_url"
      %data "$desc" "good-client" "$url" true
      %data "$desc" "bad-client" "$url" true

      # pod -> world
      desc="pod -> world"
      url="https://www.google.com/robots.txt"
      %data "$desc" "good-client" "$url" true
      %data "$desc" "bad-client" "$url" true
    End

    It "should $( [[ \"$4\" == \"false\" ]] && echo NOT ) allow ${2} to access for ${1}"
      case "$3" in
        # ShellSpec has a hard time running local function calls within
        #  Parameters:dynamic
        "get_server_pod_url") url=$(get_server_pod_url) ;;
        "get_gateway_external_url") url=$(get_gateway_external_url) ;;
        *) url="$3" ;;
      esac
      When call client_curl "${2}" "$url"
      if [[ "$4" == "true" ]]; then
        The status should be success
        The output as yq '.status' should equal '200'
      else
        The status should not be success
      fi
    End
  End
End
