#shellcheck shell=sh

# Wrapper for talosctl that suppresses non-critical warnings while preserving other stderr
talosctl() {
  command talosctl "$@" 2> >(grep -v "server version.*is older than client version" >&2)
}

# Check if value is present (not null, empty string, empty list, empty map)
is_present() {
  [ "${is_present:-}" != "null" ] && [ "${is_present:-}" != "" ] && [ "${is_present:-}" != "[]" ] && [ "${is_present:-}" != "{}" ]
}

# Check if CIDR is IPv6
is_ipv6_cidr() {
  # A RegEx for IPv6 is painfully complicated
  #  We could use an external tool:
  #   `ipcalc -6 -c "${is_ipv6_cidr:-}" 2>/dev/null`
  #  ...but it's such a niche edgecase.
  #
  # I'll wait for it to become a problem, then improve it (if necessary)
  echo -n "${is_ipv6_cidr:-}" | grep -q ':'
}
