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

publish_images() {
  local version="$1"; shift

  REGISTRIES="$REGISTRIES" \
  IMAGE_OPERATOR="$IMAGE_ORG/$IMAGE_OPERATOR" \
  IMAGE_WEBHOOK="$IMAGE_ORG/$IMAGE_WEBHOOK" \
  IMAGE_RELOADER="$IMAGE_ORG/$IMAGE_RELOADER" \
  CPU_ARCHS="$CPU_ARCHS" \
  ./scripts/push-docker-image.sh
}


create_git_tags(){
  local version="$1"; shift

  git tag -a "v${version}" -m "v${version}"
  git tag -a "pkg/apis/monitoring/v${version}" -m "v${version}"
  git tag -a "pkg/client/monitoring/v${version}" -m "v${version}"

}

main() {
  # all files references must be relative to the root of the project
  cd "$PROJECT_ROOT"

  create_git_tags "$version"
  echo -e "\n\n ❯  git push --tags origin"

  return $?
}

main "$@"

