#!/bin/bash

set +o posix # Enable for process substitution <(...), aka. "party hat"

omit_all_matches='false'
num_commits=256

opts=0
while getopts 'n:y' flag; do
  case "${flag}" in
    n) num_commits=${OPTARG}; (( opts++ ));;
    y) omit_all_matches='true' ;;
    \?) exit 1 ;;
    *) echo "Unexpected option ${flag}"; exit 1 ;;
  esac

  (( opts++ ))
done
shift ${opts}

remote="${1:-api}"
branch="master"
subtree_dir="staging/${remote}"

# slurp command output by newline, creating an array
remote_commits=( $(git rev-list --reverse --no-merges -n "${num_commits}" "${remote}/${branch}" ) )
local_commits=( $(git rev-list --reverse --no-merges -n "${num_commits}" HEAD -- "${subtree_dir}") )

declare -a local_msgs
for commit in "${local_commits[@]}"; do
    # slurp multiline output as single element
    local_msgs+=("$(git log --format=%B -n 1 ${commit})")
done


function print_progress {
    completed=${1}
    out_of=${2}
    resolution=${3:-1}

    if (( completed % resolution > 0 )); then
        return
    fi

    (( progress = 100 * completed / out_of ))

    printf "\e[3D%d%%" "${progress}"
}

function confirm {
    while true; do
        read -p "omit from cherrypick set? [y/n]: " yn
        case $yn in
            [Yy]*) printf "omitting\n" ; return 0 ;;
            [Nn]*) printf "keeping\n" ; return  1 ;;
        esac
    done
}

function omit {
    unset remote_commits["${1}"]
    unset local_msgs["${2}"]
}

printf "omitting non-merge commits in ${remote}/${branch} with messages not found in local commits that touch ${subtree_dir}\n"

i=1
for rc in "${remote_commits[@]}"; do
    rmsg="$(git log --format=%B -n 1 ${rc})"
    j=1
    for lmsg in "${local_msgs[@]}"; do
        if [[ $lmsg =~ "${rmsg}"|"${rc:0:7}" ]]; then
            # if there's no diff, immediately remove it
            ( ${omit_all_matches} || diff -q -a -B <(printf "${lmsg}") <(printf "${rmsg}") ) && omit "${i}" "${j}" && break

            # else, show diff for inspection
            printf '%*s\n' "$(tput cols)" '' | tr ' ' -
            printf "potential matching remote commit: %s\n" "${rc}"
            diff -s -y -a -B --suppress-common-lines <(printf "${lmsg}") <(printf "${rmsg}")
            confirm && omit "${i}" "${j}" && break
        fi
        (( j++ ))
    done
    print_progress "${i}" "${num_commits}" 2

    (( i++ ))
done

printf "cherry-picking %d commits upstream->downstream:\n" "${#remote_commits[@]}"
while read rc; do
    git log --oneline -n 1 ${rc}
done < <(git rev-list --no-merges --reverse "${remote_commits[@]}" | grep -f <(printf "%s\n" "${remote_commits[@]}"))

git rev-list --no-merges --reverse "${remote_commits[@]}" | grep -f <(printf "%s\n" "${remote_commits[@]}") | git cherry-pick --strategy=recursive -Xsubtree="${staging_dir}" -x --stdin

