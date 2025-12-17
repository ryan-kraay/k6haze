#shellcheck shell=sh
shellspec_syntax 'shellspec_modifier_jq'

# Network DLS 
# see: https://github.com/hoodlm/JunkDrawer/blob/41f38b071527c621b67d34f28b16ee92bd8d0898/readyornot/spec/network_spec.sh
# source: https://loganhood.com/2024/01/09/shellspec

shellspec_modifier_jq() {
  shellspec_syntax_param count [ $# -ge 1 ] || return 0

  # shellcheck disable=SC2034
  SHELLSPEC_META='text'
  if [ "${SHELLSPEC_SUBJECT+x}" ]; then
    if ! SHELLSPEC_SUBJECT=$(echo "$SHELLSPEC_SUBJECT" | yq -r "$1"); then
      echo "jq filter is missing or invalid[$1]" >&2
      unset SHELLSPEC_SUBJECT ||:
      return 1
    fi
  else
    unset SHELLSPEC_SUBJECT ||:
  fi
  shift

  case $# in
    0) shellspec_syntax_dispatch modifier ;;
    *) shellspec_syntax_dispatch modifier "$@" ;;
  esac
}
