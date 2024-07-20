#!/usr/bin/env bash
# This script is only used in the container, see Dockerfile.

DIR="/host" # csi-node mount / of the node to /host in the container
BIN="$(basename "$0")"

iscsid_pid=$(pgrep iscsid)

echo "$@"

if [ -d "$DIR" ]; then
    echo "entering nsenter"
    nsenter --mount="/proc/${iscsid_pid}/ns/mnt" --net="/proc/${iscsid_pid}/ns/net" -- "/usr/local/sbin/$BIN" "$@"
fi
