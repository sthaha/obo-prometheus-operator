#!/usr/bin/env bash
set -e -u -o pipefail

declare PROJECT_ROOT
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

declare REGISTRIES="${REGISTRIES:-"quay.io"}"
declare IMAGE_ORG="${IMAGE_ORG:-sthaha}"
declare IMAGE_OPERATOR="${IMAGE_OPERATOR:-"obo-prometheus-operator"}"
declare IMAGE_RELOADER="${IMAGE_RELOADER:-"obo-prometheus-config-reloader"}"
declare IMAGE_WEBHOOK="${IMAGE_WEBHOOK:="obo-admission-webhook"}"
declare CPU_ARCHS="${CPU_ARCHS:="amd64"}"

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


publish_images() {
  local version="$1"; shift

  REGISTRIES="$REGISTRIES" \
  IMAGE_OPERATOR="$IMAGE_ORG/$IMAGE_OPERATOR" \
  IMAGE_WEBHOOK="$IMAGE_ORG/$IMAGE_WEBHOOK" \
  IMAGE_RELOADER="$IMAGE_ORG/$IMAGE_RELOADER" \
  CPU_ARCHS="$CPU_ARCHS" \
  ./scripts/push-docker-image.sh
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

  find \( -path "./.git" -o -path "./rhobs" \) -prune -o -type f -exec \
    sed -i  \
      -e 's|monitoring.coreos.com|monitoring.rhobs|g'   \
      -e 's|+kubebuilder:resource:categories="prometheus-operator".*|+kubebuilder:resource:categories="rhobs-prometheus-operator"|g' \
      -e 's|github.com/prometheus-operator/prometheus-operator|github.com/rhobs/obo-prometheus-operator|g' \
  {} \;
}

create_git_tags(){
  local version="$1"; shift

  git add .
  git commit -m "rhobs v${version} fork"

  git tag -a "v${version}" -m "v${version}"
  git tag -a "pkg/apis/monitoring/v${version}" -m "v${version}"


  echo "git push --tags origin"
}

main() {
  # all files references must be relative to the root of the project
  cd "$PROJECT_ROOT"

  bumpup_version
  local version
  version="$(head -n1 VERSION)"

  info "Version bumped to: $version"

  # change_api_group
  # make generate

  # generate_stripped_down_crds

  # create_git_tags "$version"
  # publish_images "$version"

  return $?
}

main "$@"

