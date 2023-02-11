#!/usr/bin/env bash


# Init
set -euo pipefail
basedir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."


# Functions
function main() {
    local rc=0
    check_requirement

    pushd "${bamboo_dockerFileDir}"
        build_latest

        {
            docker_login
            publish_latest
            publish_version
        } || {
            rc=$?
        }
        docker_logout
    popd

    return $rc
}

function check_requirement() {
    local rc=0

    which docker >/dev/null 2>&1 || {
        echo "'docker' command is required" >&2
        ((rc++))
    }

    [ -z "${bamboo_dockerFileDir:-}" ] && {
        echo "Missing Bamboo variable 'dockerFileDir'" >&2
        ((rc++))
    }

    [ -z "${bamboo_imageName:-}" ] && {
        echo "Missing Bamboo variable 'imageName'" >&2
        ((rc++))
    }

    [ -z "${bamboo_imageVersion:-}" ] && {
        echo "Missing Bamboo variable 'imageVersion'. Only latest will be published" >&2
    }

    return $rc
}

function build_latest() {
    image_id="${bamboo_docker_registry_host}/${bamboo_imageName}"
    echo "  > Build image '${image_id}'"
    docker build -t "${image_id}" "${basedir}/${bamboo_dockerFileDir}"
}

function publish_latest() {
    docker_push "${image_id}"
}

function publish_version() {
    [ ! -z "${bamboo_imageVersion:-}" ] && {
        local image_version_id="${bamboo_docker_registry_host}/${bamboo_imageName}:${bamboo_imageVersion}"
        [[ "${bamboo_withBuildNumber}" == "true" ]] && {
            image_version_id="${image_version_id}-${bamboo_buildNumber}"
        }
        docker tag "${image_id}" "${image_version_id}" && docker_push "${image_version_id}"
    }
}


# Docker
function docker_login() {
    docker --config "${basedir}/docker-config.json" login -u "${bamboo_docker_registry_userpassword_login}" -p "${bamboo_docker_registry_userpassword_password}" "${bamboo_docker_registry_host}"
}

function docker_logout() {
    rm -rf "${basedir}/docker-config.json"
}

function docker_push() {
    echo "  > Publish image '${1}'"
    docker --config "${basedir}/docker-config.json" push "${1}"
}


# Run
main "$@"
