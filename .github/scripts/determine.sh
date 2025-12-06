#!/usr/bin/env bash
#shellcheck shell=bash

info() {
  if [ -n "${VERBOSE:-}" ]; then
    echo "[INFO] $*" >&2
  fi
}

determine_changes() {
  declare -A changes=(
    [changed_github]=false
    [changed_github_spec]=false
    [changed_talos]=false
    [changed_talos_spec]=false
    [changed_k8s]=false
    [changed_k8s_spec]=false
  )

  while IFS= read -r file; do
    info "Processing file: $file"
    case "$file" in
      terraform/*/spec/*)
        project=$(echo "$file" | cut -d/ -f2)
        info "...matched spec for project: $project"
        changes["changed_${project}_spec"]=true
        ;;
      terraform/*)
        project=$(echo "$file" | cut -d/ -f2)
        info "...matched terraform for project: $project"
        changes["changed_${project}"]=true
        # When terraform changes, we will always run the specs
        changes["changed_${project}_spec"]=true
        ;;
      */.gitignore|.gitignore)
        ;& # fallthrough
      */README.md|README.md)
        info "...ignored"
        ;;
      *)
        # In the event that "something" outside of terraform changed (ie: devbox.json)
        #  we will retrigger a terraform deployment of everything
        info "...unknown file. Marking everything as changed"
        for project in github talos k8s; do
          changes["changed_${project}"]=true
          changes["changed_${project}_spec"]=true
        done
        ;;
    esac
  done

  if [[ "${changes[changed_github]}" == true ]]; then
    info "GitHub changed, cascading to talos"
    changes["changed_talos"]=true
    changes["changed_talos_spec"]=true
  fi
  if [[ "${changes[changed_talos]}" == true ]]; then
    info "Talos changed, cascading to k8s"
    changes["changed_k8s"]=true
    changes["changed_k8s_spec"]=true
  fi

  # Render the results as json
  local args=()
  for key in "${!changes[@]}"; do
    args+=(--argjson "$key" "${changes[$key]}")
  done
  info "Final changes: ${!changes[*]}"
  jq -cn '$ARGS.named' "${args[@]}"
}

if [ -z "${SHELLSPEC_ROOT}" ]; then
  # When running via the cli, run this
  determine_changes
fi
