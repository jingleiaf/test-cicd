#!/usr/bin/env bash


# Init
set -euo pipefail
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."


# Functions
function main() {
    local rc=0
    check_requirement

    pushd "${dockerFile_dir}"
        build_latest
        {
            rc=$?
        }
    popd

    return $rc
}

function check_requirement() {
    local rc=0

    which docker >/dev/null 2>&1 || {
        echo "'docker' command is required" >&2
        ((rc++))
    }

    [ -z "${dockerFile_dir:-}" ] && {
        echo "Missing variable 'dockerFileDir'" >&2
        ((rc++))
    }

    [ -z "${imageName:-}" ] && {
        echo "Missing variable 'imageName'" >&2
        ((rc++))
    }

    [ -z "${imageVersion:-}" ] && {
        echo "Missing variable 'imageVersion'. Only latest will be published" >&2
    }

    return $rc
}

function build_latest() {
    image_id="${imageName}"
    echo "  > Build image '${image_id}'"
    docker build -t "${image_id}" "${basedir}/${dockerFile_dir}"
}

# Run
main "$@"
