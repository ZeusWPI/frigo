#!/usr/bin/env sh
if [[ -n "$1" && ! "$1" =~ ^-.* ]]; then
    host="$1"
    shift
else
    host="frigo"
fi
nixos-rebuild -v --flake ".#$host" --target-host "root@$host" --build-host localhost switch "$@"
