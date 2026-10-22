#!/usr/bin/env bash
#
# Build the backup image and publish it to Docker Hub.
#
#   bin/build.sh [tag]
#       Builds for linux/amd64 AND linux/arm64 and pushes a multi-arch
#       manifest as nails/docker-env-backup:<tag> (default: latest).
#       Works the same from an Apple Silicon Mac or an x86 machine; the
#       non-native architecture is built under emulation, so it is slower.
#
#   LOCAL=1 bin/build.sh [tag]
#       Builds for the host architecture only and loads the result into the
#       local Docker image store. Nothing is pushed. Use this to test changes.
#
# Environment:
#   PLATFORMS  Platforms to build (default: linux/amd64,linux/arm64)
#   BUILDER    buildx builder to use/create (default: nails-multiarch)
#
# Do not use `docker push nails/docker-env-backup`: it pushes the
# single-architecture image from the local store over the multi-arch tag.

set -euo pipefail

REPO="nails/docker-env-backup"
TAG="${1:-latest}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"
BUILDER="${BUILDER:-nails-multiarch}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="$REPO:$TAG"

# --------------------------------------------------------------------------
# Local, single-architecture build (no push)
# --------------------------------------------------------------------------

if [ "${LOCAL:-0}" = "1" ]; then
    echo "==> [local] $IMAGE"
    docker build -t "$IMAGE" "$ROOT"
    exit 0
fi

# --------------------------------------------------------------------------
# Multi-architecture build and push
# --------------------------------------------------------------------------

# The default "docker" driver cannot build multiple platforms into one
# manifest, so use a dedicated docker-container builder. It is created once
# and reused; it does not change the machine's default builder.
if ! docker buildx inspect "$BUILDER" >/dev/null 2>&1; then
    echo "==> Creating buildx builder '$BUILDER'"
    docker buildx create --name "$BUILDER" --driver docker-container --bootstrap
fi

echo "==> [$PLATFORMS] $IMAGE"
docker buildx build \
    --builder "$BUILDER" \
    --platform "$PLATFORMS" \
    --pull \
    --push \
    --tag "$IMAGE" \
    "$ROOT"

# Verify the published manifest has every requested platform, so an
# incomplete push fails loudly here instead of on a production server.
published=$(docker buildx imagetools inspect "$IMAGE" \
    | awk '/Platform:/ {print $2}' \
    | grep -v '^unknown/' \
    | sort -u \
    | paste -sd, -)

for platform in ${PLATFORMS//,/ }; do
    case ",$published," in
        *",$platform,"*) ;;
        *)
            echo "ERROR: $IMAGE is missing $platform (published: ${published:-none})" >&2
            exit 1
            ;;
    esac
done

echo "==> OK $IMAGE [$published]"
