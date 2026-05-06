# Compatibility history

Scheduled and full-matrix manual runs persist raw status snapshots here through the bot PR workflow.

- `latest.json` points at the newest recorded run.
- `index.json` keeps a compact list of recent runs, capped to the 100 most recent entries.
- `runs/<run_id>/<target_os>.json` stores the raw per-OS `status.json` payloads uploaded by the build workflow.

The bot opens PRs for history updates; those PRs are reviewed and squash-merged manually rather than auto-merged.
