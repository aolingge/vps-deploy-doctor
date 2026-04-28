# Repository Agent Instructions

## Scope

- Follow `README.md`, `README.zh-CN.md`, `bin/`, `checks/`, and `test/` before adding new tooling.
- Keep diagnostics read-only by default: no restarts, firewall edits, config writes, or log uploads unless explicitly requested.
- Do not commit secrets, tokens, cookies, generated credentials, browser profiles, private logs, or local machine paths.

## Commands

- Validate: `bash test/validate.sh`.
- Local smoke: `bash bin/vps-deploy-doctor.sh --json --url http://127.0.0.1 --port 8080` when diagnostic behavior changes.

## Verification

Run the narrowest relevant validation after edits. Keep checks local or read-only unless the user explicitly asks for live VPS diagnostics.

## Git

- Preserve unrelated dirty changes.
- Do not rewrite history, delete branches, push, publish, or open PRs without explicit confirmation.
