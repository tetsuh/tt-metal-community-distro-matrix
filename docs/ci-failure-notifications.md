# CI failure notifications

The weekly scheduled full-matrix run and manual `target_os=all` runs create a
public GitHub Issue when the workflow setup or build matrix fails.

Single-target manual runs do not create notification issues. Those runs are
usually active debugging sessions, so opening a public issue for every failed
attempt would create noise.

## Deduplication

The notification job uses one open issue title:

```text
CI failure: full-matrix build-tt-metal
```

If that issue already exists, new failing scheduled/full-matrix runs add a
comment instead of opening another issue. This keeps repeated weekly failures
visible without creating duplicate triage threads.

## What the issue contains

Each issue or comment includes:

- the workflow run URL;
- the event type;
- the target selection;
- the `tt-metal` repository and ref;
- setup/build aggregate results;
- failed job names and links, when GitHub exposes them through the Actions API.

## Triage policy

The notification is a triage signal, not an automatic diagnosis.

1. Inspect the failed job logs; when build jobs ran, also inspect uploaded
   `status.json` artifacts.
2. Decide whether the result is a real compatibility regression or a transient
   infrastructure failure.
3. If a bot README/history PR exists and the failure should be published as
   current compatibility state, merge the PR after review.
4. For setup-level failures or early build failures with no bot PR, triage
   directly from the logs and rerun or fix as needed.
5. Close the notification issue manually after triage or after a fix lands.

Green follow-up runs do not auto-close the issue. A maintainer should close it
after deciding the failure is resolved or no longer actionable.
