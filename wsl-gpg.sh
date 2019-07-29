#!/usr/bin/env bash

#
# This script can be used in WSL with e.g. git's `gpg.program` configuration
# value as a way to run the Windows install of GPG from WSL. My main use for
# it is ensuring GPG has access to a smart card for git commit/tag signing.
#

declare -a allArgs
i=0

for arg in "$@"
do
    case "$arg" in
        /*)
            allArgs[$i]="$allArgs $(wslpath -w $arg)"
            ;;
        *)
            allArgs[$i]="$allArgs $arg"
            ;;
    esac
    i=$((i++))
done

gpg.exe $allArgs
