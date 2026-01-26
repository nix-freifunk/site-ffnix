#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source "${SCRIPT_DIR}/functions-sign.sh"

declare -A SIGKEYS


SIGKEYS["Tom/herbetom"]="1c5647e53ee22756d52ce4c1830b27472d9381b808eb9e46bba99f8433406195"
SIGKEYS["github-actions-ci"]="0079eb306a3443eaed4d2201809944d39e902c0aa1490cd7aa7671d955dd0259"

function usage() {
        echo "Usage: $0 <release-version> <branch>"
        echo "Example: $0 2.0.0 stable"
        exit 1
}

function cleanup() {
        rm -rf "$TEMP_DIR"
}

RELEASE_VERSION="${1:-}"
BRANCH="${2:-}"

[ -z "$RELEASE_VERSION" ] && usage
[ -z "$BRANCH" ] && usage

# Create Temporary working directory
TEMP_DIR="$(mktemp -d)"

MANIFEST_PATH="${TEMP_DIR}/checking.manifest"

# Download released manifest archive
MANIFEST_URL="https://fw.ff.tomhe.de/images/${RELEASE_VERSION}/images/sysupgrade/${BRANCH}.manifest"
echo "Download manifest from $MANIFEST_URL"
curl -s -L -o "${MANIFEST_PATH}" "${MANIFEST_URL}"

for name in "${!SIGKEYS[@]}"
do
        valid_ci_signature="$(get_valid_signature "${MANIFEST_PATH}" "${SIGKEYS[$name]}")"

        # Check if manifest is signed with the key under test
        if [ -n "$valid_ci_signature" ]; then
                echo "Manifest is signed with the \"${name}\" key"
                echo "Signature: $valid_ci_signature"
        fi
done

cleanup
