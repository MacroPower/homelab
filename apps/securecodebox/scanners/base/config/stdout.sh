#!/usr/bin/env bash
set -euo pipefail

function notify() {
    echo "$ENTIRE_PAYLOAD"
}

function main() {
    notify
}

main "$@"
