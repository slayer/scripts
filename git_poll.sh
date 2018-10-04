#!/bin/bash
# Script:
#     git_poll.sh <branch>
# Purpose:
#     Poll your Rails repository for changes.

set -e
BRANCH="${1:-master}"
PROJECT="${PROJECT:-flyhub_prod}"
BASEDIR="${BASEDIR:-/opt/${PROJECT}}"

# Use the flock(1) utility to guard against long-running fetch or merge
# operations using the flock(2) system call. On Debian-based systems,
# this tool is found in the util-linux package.
(
    flock -n 9

    cd "${BASEDIR}"
    git fetch origin ${BRANCH}

    # Check if heads point to the same commit.
    if ! cmp --quiet <(git rev-parse ${BRANCH}) <(git rev-parse origin/${BRANCH}); then
        git pull --force origin ${BRANCH}
        bundle
        bundle exec rake assets:precompile
        sudo systemctl restart flyhub
        # touch "${BASEDIR}/tmp/restart.txt" 2>/dev/null
    fi
) 9> "/var/lock/git_poll-${PROJECT}-${BRANCH}"
