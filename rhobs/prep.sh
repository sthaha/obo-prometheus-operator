#!/usr/bin/env bash
set -e -u -o pipefail

declare PROJECT_ROOT
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

info(){
  echo "INFO: $*"
}

# bumps up VERSION file to <upstream-version>-rhobs<patch>
# e.g. upstream 1.2.3 will be bumped to 1.2.3-rhobs1
# and if git tag 1.2.3-rhobs1 already exists, it will be bumped to 1.2.3-rhobs2
bumpup_version(){
  # get all tags with
  info "Bumping up the version"

  local version
  version="$(head -n1 VERSION)"

  # remove any trailing rhobs
  local upstream_version="${version//-rhobs*}"
  echo "found upstream version: $upstream_version"

  local patch
  # git tag | grep "^v$upstream_version-rhobs" | wc -l
  # NOTE: grep || true prevents grep from setting non-zero exit code
  # if there are no -rhobs tag

  patch="$( git tag | { grep "^v$upstream_version-rhobs" || true; } | wc -l )"
  (( patch+=1 ))

  rhobs_version="$upstream_version-rhobs$patch"

  echo "Updating version to $rhobs_version"
  echo "$rhobs_version" > VERSION
}


generate_stripped_down_crds(){
  # NOTE:
  mkdir -p example/stripped-down-crds
  make stripped-down-crds.yaml
  mv stripped-down-crds.yaml example/stripped-down-crds/all.yaml
}


change_api_group(){
  info "Changing api group to monitoring.rhobs"

  rm -f example/prometheus-operator-crd-full/monitoring.coreos.com*
  rm -f example/prometheus-operator-crd/monitoring.coreos.com*

  # NOTE: find command changes
  #  * kubebuilder group to monitoring.rhobs
  #  * the category  to rhobs-prometheus-operator
  #  * removes all shortnames

  find \( -path "./.git" \
          -o -path "./Documentation" \
          -o -path "./rhobs" \) -prune -o \
    -type f -exec \
    sed -i  \
      -e 's|monitoring.coreos.com|monitoring.rhobs|g'   \
      -e 's|+kubebuilder:resource:categories="prometheus-operator".*|+kubebuilder:resource:categories="rhobs-prometheus-operator"|g' \
      -e 's|github.com/prometheus-operator/prometheus-operator|github.com/rhobs/obo-prometheus-operator|g' \
  {} \;

  # replace only the api group in docs and not the links
  find ./Documentation \
    -type f -exec \
    sed -i  -e 's|monitoring.coreos.com|monitoring.rhobs|g'   \
  {} \;

  sed -e 's|monitoring\\.coreos\\.com|monitoring\\.rhobs|g' -i .mdox.validate.yaml
}



main() {
  # all files references must be relative to the root of the project
  cd "$PROJECT_ROOT"

  bumpup_version
  local version
  version="$(head -n1 VERSION)"

  info "Version bumped to: $version"

  change_api_group
  make --always-make format generate
  make --always-make docs

  git add .
  git commit -m "chore(release) v${version}"

  make check-docs check-golang check-license check-metrics
  make test-unit

  git diff --shortstat --exit-code
  # generate_stripped_down_crds
}

main "$@"

