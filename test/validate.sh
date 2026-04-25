#!/usr/bin/env bash
set -euo pipefail

bash -n bin/vps-deploy-doctor.sh

output="$(bash bin/vps-deploy-doctor.sh --help)"
grep -q "read-only VPS deployment diagnostics" <<< "$output"

json_output="$(bash bin/vps-deploy-doctor.sh --json --url http://127.0.0.1 --port 65535 || true)"
grep -q '"summary"' <<< "$json_output"

echo "Validation passed"
