#!/usr/bin/env bash
# Lint and template every Helm chart in this repository.
#
# Runs `helm dependency build && helm lint && helm template` against the
# parent chart, platform-addons, team-addons, and every default-add-ons/*
# wrapper chart discovered under them. Exits non-zero on the first failure
# (Constitution Principle II: every chart must be independently
# `helm lint`-able).
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

# Top-level app-of-apps charts, plus every wrapper chart nested under a
# `default-add-ons/` directory anywhere in the repo (depth-first, sorted).
charts=(
    "chart"
    "platform-addons"
    "team-addons"
)
while IFS= read -r dir; do
    charts+=("$dir")
done < <(find . -type d -path '*/default-add-ons/*' -not -path '*/default-add-ons' \
    -exec test -f '{}/Chart.yaml' \; -print | sed 's#^\./##' | sort)

echo "Discovered ${#charts[@]} chart(s) to lint:"
printf '  - %s\n' "${charts[@]}"
echo

failures=0
for chart in "${charts[@]}"; do
    if [ ! -f "$chart/Chart.yaml" ]; then
        echo "==> SKIP $chart (no Chart.yaml found yet)"
        continue
    fi

    echo "==> $chart"
    if ! (
        set -e
        helm dependency build "$chart"
        helm lint "$chart"
        helm template "$chart" >/dev/null
    ); then
        echo "FAILED: $chart"
        failures=1
        break
    fi
    echo
done

if [ "$failures" -ne 0 ]; then
    echo "lint-all.sh: FAILED"
    exit 1
fi

echo "lint-all.sh: all charts passed"
