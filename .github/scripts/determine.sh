#!/usr/bin/env bash
#shellcheck shell=bash

info() {
  if [ -n "${VERBOSE:-}" ]; then
    echo "[INFO] $*" >&2
  fi
}

determine_changes() {
  declare -A changes=(
    [changed_root_spec]=false
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
      spec/*)
        info "...matched root spec"
        changes["changed_root_spec"]=true
        ;;
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
        changes["changed_root_spec"]=true
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

  # Convert the bash associative array to a simple properties format that yq will convert into json
  local props=""
  for key in "${!changes[@]}"; do
    props+="$key=${changes[$key]}"$'\n'
  done

  info "Final changes: ${!changes[*]}"
  # Convert props format to JSON, converting string booleans to actual booleans
  # This needs to be stored as a SINGLE line of JSON (otherwise, we cannot use it as a github secret)
  echo -n "$props" | yq -p props -o json -I 0 'with_entries(.value |= (. == "true"))'
}

if [ -z "${SHELLSPEC_ROOT}" ]; then
  # When running via the cli, run this
  determine_changes
fi
