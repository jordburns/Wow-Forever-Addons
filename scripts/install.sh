#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ADDON="${ADDON:-Class_Macros}"
WOW="${WOW:-/Applications/World of Warcraft}"

DEFAULT_CLIENT="_forever_"

clients=("$@")
if [[ ${#clients[@]} -eq 0 ]]; then
    for installed in "$WOW"/_*_/Interface/AddOns/"$ADDON"; do
        [[ -d "$installed" ]] && clients+=("$(basename "$(dirname "$(dirname "$(dirname "$installed")")")")")
    done
fi
if [[ ${#clients[@]} -eq 0 ]]; then
    clients=("$DEFAULT_CLIENT")
fi

for client in "${clients[@]}"; do
    addons="$WOW/$client/Interface/AddOns"
    if [[ ! -d "$addons" ]]; then
        echo "Skipped $client: $addons does not exist"
        continue
    fi
    rsync -a --delete --exclude ".DS_Store" "$ROOT/$ADDON/" "$addons/$ADDON/"
    echo "Installed $ADDON into $addons"
done
echo "In game: /reload for changed files, or restart the game if you added or removed a file in the .toc."
