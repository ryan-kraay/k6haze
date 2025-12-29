#shellcheck shell=sh

# Wrapper for kubectl that includes stderr and defaults to json output
kubectl() {
  command kubectl "$@" -o json
}

# Check if value is present (not null, empty string, empty list, empty map)
is_present() {
  [ "${is_present:-}" != "null" ] && [ "${is_present:-}" != "" ] && [ "${is_present:-}" != "[]" ] && [ "${is_present:-}" != "{}" ]
}
